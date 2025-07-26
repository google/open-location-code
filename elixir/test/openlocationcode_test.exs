defmodule SoferBe.Places.APIs.OpenLocationCodeTest do
  use ExUnit.Case

  # --- Validity Tests ---
  describe "validity" do
    test "valid?/1 matches test data" do
      for test_case <- read_validity_csv("validityTests.csv") do
        assert OpenLocationCode.valid?(test_case.code) == test_case.is_valid,
               "Failed on code: #{test_case.code}"
      end

      assert OpenLocationCode.valid?("849VGJQF") == false
      assert OpenLocationCode.valid?(1_234_567_890) == false
    end

    test "short?/1 matches test data" do
      for test_case <- read_validity_csv("validityTests.csv") do
        assert OpenLocationCode.short?(test_case.code) == test_case.is_short,
               "Failed on code: #{test_case.code}"
      end
    end

    test "full?/1 matches test data" do
      for test_case <- read_validity_csv("validityTests.csv") do
        assert OpenLocationCode.full?(test_case.code) == test_case.is_full,
               "Failed on code: #{test_case.code}"
      end
    end
  end

  # --- Shortening and Recovery Tests ---
  describe "shortening" do
    test "shorten/3 and recover_nearest/3 match test data" do
      for test_case <- read_shortening_csv("shortCodeTests.csv") do
        # Test shortening
        if test_case.test_type in ["B", "S"] do
          assert OpenLocationCode.shorten(
                   test_case.full_code,
                   test_case.lat,
                   test_case.lng
                 ) == {:ok, test_case.short_code}
        end

        # Test recovery
        if test_case.test_type in ["B", "R"] do
          assert OpenLocationCode.recover_nearest(
                   test_case.short_code,
                   test_case.lat,
                   test_case.lng
                 ) == {:ok, test_case.full_code}
        end
      end

      assert OpenLocationCode.shorten("CJ+2VX", 1.2, 2.3) == {:error, :full_code_expected}
    end
  end

  # --- Encoding Tests ---
  describe "encoding" do
    test "encode/3 matches test data with allowed error rate" do
      data = read_encoding_csv("encoding.csv")
      allowed_error_rate = 0.05

      results =
        for test_case <- data do
          {:ok, result} =
            OpenLocationCode.encode(
              test_case.lat,
              test_case.lng,
              test_case.length
            )

          if result == test_case.code do
            true
          else
            IO.puts(
              "encode(#{test_case.lat}, #{test_case.lng}, #{test_case.length}) want #{test_case.code}, got #{result}"
            )

            false
          end
        end

      errors = Enum.count(results, &(not &1))
      error_rate = errors / length(data)

      assert error_rate <= allowed_error_rate,
             "Encode error rate too high: #{error_rate} (allowed: #{allowed_error_rate})"
    end

    test "location_to_integers/2 matches test data with precision tolerance" do
      for test_case <- read_encoding_csv("encoding.csv") do
        case OpenLocationCode.location_to_integers(test_case.lat, test_case.lng) do
          {:ok, {got_lat_int, got_lng_int}} ->
            # Due to floating point precision limitations, we may get values 1 less than expected
            assert test_case.lat_int - 1 <= got_lat_int and got_lat_int <= test_case.lat_int,
                   "Latitude conversion #{test_case.lat}: want #{test_case.lat_int} got #{got_lat_int}"

            assert test_case.lng_int - 1 <= got_lng_int and got_lng_int <= test_case.lng_int,
                   "Longitude conversion #{test_case.lng}: want #{test_case.lng_int} got #{got_lng_int}"

          _ ->
            flunk("location_to_integers should return a tuple")
        end
      end
    end

    test "encode_integers/3 matches test data exactly" do
      for test_case <- read_encoding_csv("encoding.csv") do
        assert OpenLocationCode.encode_integers(
                 test_case.lat_int,
                 test_case.lng_int,
                 test_case.length
               ) == {:ok, test_case.code},
               "Encode integers failed for: #{inspect(test_case)}"
      end
    end
  end

  # --- Decoding Tests ---
  describe "decoding" do
    test "decode/1 matches test data" do
      for test_case <- read_decoding_csv("decoding.csv") do
        {:ok, %OpenLocationCode.CodeArea{} = decoded} = OpenLocationCode.decode(test_case.code)
        precision = 10

        assert_almost_equal(decoded.latitude_lo, test_case.lat_lo, precision, test_case)
        assert_almost_equal(decoded.longitude_lo, test_case.lng_lo, precision, test_case)
        assert_almost_equal(decoded.latitude_hi, test_case.lat_hi, precision, test_case)
        assert_almost_equal(decoded.longitude_hi, test_case.lng_hi, precision, test_case)
      end

      assert OpenLocationCode.decode("CJ+2VX") == {:error, :full_code_expected}
      assert OpenLocationCode.decode(1_234_567_890) == {:error, :invalid_code}
      assert OpenLocationCode.decode("asdsa+21") == {:error, :invalid_code}
    end
  end

  # --- Private Helper Functions for Parsing CSVs ---

  defp get_path(path) do
    "../test_data/" <> path
  end

  defp read_validity_csv(path) do
    path
    |> get_path()
    |> File.stream!()
    |> Stream.filter(&(not String.starts_with?(&1, "#")))
    |> Enum.map(fn line ->
      [code, is_valid, is_short, is_full] = String.trim(line) |> String.split(",")

      %{
        code: code,
        is_valid: is_valid == "true",
        is_short: is_short == "true",
        is_full: is_full == "true"
      }
    end)
  end

  defp read_shortening_csv(path) do
    path
    |> get_path()
    |> File.stream!()
    |> Stream.filter(&(not String.starts_with?(&1, "#")))
    |> Enum.map(fn line ->
      [full_code, lat, lng, short_code, test_type] = String.trim(line) |> String.split(",")

      %{
        full_code: full_code,
        lat: String.to_float(lat),
        lng: String.to_float(lng),
        short_code: short_code,
        test_type: test_type
      }
    end)
  end

  defp read_encoding_csv(path) do
    path
    |> get_path()
    |> File.stream!()
    |> Enum.with_index()
    |> Stream.filter(&(not String.starts_with?(elem(&1, 0), "#")))
    |> Enum.map(fn {line, index} ->
      [lat, lng, lat_int, lng_int, length, code] = String.trim(line) |> String.split(",")

      %{
        lat: elem(Float.parse(lat), 0),
        lng: elem(Float.parse(lng), 0),
        lat_int: String.to_integer(lat_int),
        lng_int: String.to_integer(lng_int),
        length: String.to_integer(length),
        code: code,
        line: index + 1
      }
    end)
  end

  defp read_decoding_csv(path) do
    path
    |> get_path()
    |> File.stream!()
    |> Stream.filter(&(not String.starts_with?(&1, "#")))
    |> Enum.map(fn line ->
      [code, _length, lat_lo, lng_lo, lat_hi, lng_hi] = String.trim(line) |> String.split(",")

      %{
        code: code,
        lat_lo: elem(Float.parse(lat_lo), 0),
        lng_lo: elem(Float.parse(lng_lo), 0),
        lat_hi: elem(Float.parse(lat_hi), 0),
        lng_hi: elem(Float.parse(lng_hi), 0)
      }
    end)
  end

  # Custom assertion to mimic Python's assertAlmostEqual
  defp assert_almost_equal(float1, float2, precision, test_case) do
    tolerance = :math.pow(10, -precision)

    assert abs(float1 - float2) < tolerance,
           "Floats not almost equal for #{inspect(test_case)}. Got #{float1}, expected #{float2}"
  end
end
