#include "openlocationcode.h"

#include <iostream>

int main() {
  // Encodes latitude and longitude into a Plus+Code.
  std::string code = openlocationcode::Encode({47.0000625, 8.0000625});
  // => "8FVC2222+22"

  // Encodes latitude and longitude into a Plus+Code with a preferred length.
  code = openlocationcode::Encode({47.0000625, 8.0000625}, 16);
  // => "8FVC2222+22GCCCCC"

  // Decodes a Plus+Code back into coordinates.
  openlocationcode::CodeArea code_area = openlocationcode::Decode(code);
  std::cout << "Code length: " << std::cout.precision(15) << std::endl;
  std::cout << code_area.GetLatitudeLo() << std::endl;   // 47.000062496
  std::cout << code_area.GetLongitudeLo() << std::endl;  // 8.00006250000001
  std::cout << code_area.GetLatitudeHi() << std::endl;   // 47.000062504
  std::cout << code_area.GetLongitudeHi() << std::endl;  // 8.0000625305176
  std::cout << code_area.GetCodeLength() << std::endl;   // 16

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
  // => "CJ+2VX"

  // Extends a Plus+Code by the given reference latitude and longitude.
  std::string recovered_code =
      openlocationcode::RecoverNearest("CJ+2VX", {51.3708675, -1.217765625});
  // => "9C3W9QCJ+2VX"
}
