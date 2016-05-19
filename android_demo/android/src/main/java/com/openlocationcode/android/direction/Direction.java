/*
 * Copyright 2016 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.openlocationcode.android.direction;

import com.google.openlocationcode.OpenLocationCode;

import java.util.Locale;

/**
 * Immutable model representing the direction between two given locations. It contains the distance,
 * the initial and the final bearing. To understand the meaning of initial and final bearing, refer
 * to http://www.onlineconversion.com/map_greatcircle_bearings.htm.
 */
public class Direction {

    private final int mDistanceInMeter;

    private final float mInitialBearing;

    private final OpenLocationCode mFromCode;

    private final OpenLocationCode mToCode;

    public Direction(
            OpenLocationCode fromCode,
            OpenLocationCode toCode,
            float distanceInMeter,
            float initialBearing) {
        mDistanceInMeter = (int) distanceInMeter;
        mInitialBearing = initialBearing;
        mFromCode = fromCode;
        mToCode = toCode;
    }

    /**
     * @return Bearing in degrees East of true North.
     */
    public float getInitialBearing() {
        return mInitialBearing;
    }

    /**
     * @return Distance in meter.
     */
    public int getDistance() {
        return mDistanceInMeter;
    }

    /**
     * @return The code representing the origin location.
     */
    public OpenLocationCode getFromCode() {
        return mFromCode;
    }

    /**
     * @return The code representing the destination location.
     */
    public OpenLocationCode getToCode() {
        return mToCode;
    }

    @Override
    public String toString() {
        return String.format(
                Locale.US,
                "Direction from code %s to %s, distance %d, initial bearing %f",
                mFromCode,
                mToCode,
                mDistanceInMeter,
                mInitialBearing);
    }
}
