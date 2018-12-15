bool indexOfMatch(String string, Pattern pattern) =>
    string.indexOf(pattern) >= 0;

bool indexOfNotMatch(String string, Pattern pattern) =>
    !indexOfMatch(string, pattern);
