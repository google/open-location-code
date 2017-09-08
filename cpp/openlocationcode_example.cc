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
  cout << "Code length: " << cout.precision(15) << endl;
  cout << code_area.GetLatitudeLo() << endl;   // 47.000062496
  cout << code_area.GetLongitudeLo() << endl;  // 8.00006250000001
  cout << code_area.GetLatitudeHi() << endl;   // 47.000062504
  cout << code_area.GetLongitudeHi() << endl;  // 8.0000625305176
  cout << code_area.GetCodeLength() << endl;   // 16

  // Checks if a Plus+Code is valid.
  bool isValid = openlocationcode::IsValid(code);
  cout << "Is valid? " << isValid << endl;
  // => true

  // Checks if a Plus+Code is full.
  bool isFull = openlocationcode::IsFull(code);
  cout << "Is full? " << isFull << endl;
  // => true

  // Checks if a Plus+Code is short.
  bool isShort = openlocationcode::IsShort(code);
  cout << "Is short? " << isShort << endl;
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
