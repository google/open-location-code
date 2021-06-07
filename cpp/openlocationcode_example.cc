#include <iomanip>
#include <iostream>

#include "openlocationcode.h"

int main() {
  // Encodes latitude and longitude into a Plus+Code.
  std::string code = openlocationcode::Encode({47.0000625, 8.0000625});
  std::cout << "Encoded: " << code << std::endl;
  // => "8FVC2222+22"

  // Encodes latitude and longitude into a Plus+Code with a preferred length.
  code = openlocationcode::Encode({47.0000625, 8.0000625}, 16);
  std::cout << "Encoded 16: " << code << std::endl;
  // => "8FVC2222+22GCCCC"

  // Decodes a Plus+Code back into coordinates.
  openlocationcode::CodeArea code_area = openlocationcode::Decode(code);
  std::cout << "Code length: " << std::fixed << std::setprecision(15) << ' '
            << code_area.GetLatitudeLo()          // 47.000062479999997
            << ' ' << code_area.GetLongitudeLo()  // 8.000062500000013
            << ' ' << code_area.GetLatitudeHi()   // 47.000062520000000
            << ' ' << code_area.GetLongitudeHi()  // 8.000062622070317
            << ' ' << code_area.GetCodeLength()   // 15
            << std::endl;

  // Checks if a Plus+Code is valid.
  bool isValid = openlocationcode::IsValid(code);
  std::cout << "Is valid? " << isValid << std::endl;
  // => true

  // Checks if a Plus+Code is full.
  bool isFull = openlocationcode::IsFull(code);
  std::cout << "Is full? " << isFull << std::endl;
  // => true

  // Checks if a Plus+Code is short.
  bool isShort = openlocationcode::IsShort(code);
  std::cout << "Is short? " << isShort << std::endl;
  // => false

  // Shorten a Plus+Codes if possible by the given reference latitude and
  // longitude.
  std::string short_code =
      openlocationcode::Shorten("9C3W9QCJ+2VX", {51.3708675, -1.217765625});
  std::cout << "Shortened: " << short_code << std::endl;
  // => "CJ+2VX"

  // Extends a Plus+Code by the given reference latitude and longitude.
  std::string recovered_code =
      openlocationcode::RecoverNearest("CJ+2VX", {51.3708675, -1.217765625});
  std::cout << "Recovered: " << recovered_code << std::endl;
  // => "9C3W9QCJ+2VX"
}
