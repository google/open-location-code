defmodule OpenLocationCode.MixProject do
  use Mix.Project

  def project do
    [
      app: :olc,
      description:
        "An Elixir 💧 implementation of Google's Open Location Code (Plus Code) system for encoding and decoding geographic locations.",
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/giriss/openlocationcode",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/giriss/openlocationcode"}
      ],
      test_coverage: [summary: [threshold: 98]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
