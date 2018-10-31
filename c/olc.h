#ifndef OLC_OPENLOCATIONCODE_H_
#define OLC_OPENLOCATIONCODE_H_

// A pair of doubles representing latitude / longitude
typedef struct OLC_LatLon {
    double lat;
    double lon;
} OLC_LatLon;

// An area defined by two corners (lo and hi) and a code length
typedef struct OLC_CodeArea {
    OLC_LatLon lo;
    OLC_LatLon hi;
    size_t len;
} OLC_CodeArea;

// Gets the center coordinates for an area
void OLC_GetCenter(const OLC_CodeArea* area, OLC_LatLon* center);

// Get the effective length for a code
size_t OLC_CodeLength(const char* code, size_t size);

// Checkers for the three obviously-named conditions
int OLC_IsValid(const char* code, size_t size);
int OLC_IsShort(const char* code, size_t size);
int OLC_IsFull(const char* code, size_t size);

// Encode a location with a given code length (which indicates precision) into
// an OLC
int OLC_Encode(const OLC_LatLon* location, size_t code_length,
               char* code, int maxlen);

// Encode a location with a default code length into an OLC
int OLC_EncodeDefault(const OLC_LatLon* location,
                      char* code, int maxlen);

// Decode an OLC into the original location
int OLC_Decode(const char* code, size_t size, OLC_CodeArea* decoded);

// Compute a (shorter) OLC for a given code and a reference location
int OLC_Shorten(const char* code, size_t size, const OLC_LatLon* reference,
                char* buf, int maxlen);

// Given a shorter OLC and a reference location, compute the original (full
// length) OLC
int OLC_RecoverNearest(const char* short_code, size_t size, const OLC_LatLon* reference,
                       char* code, int maxlen);

#endif
