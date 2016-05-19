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

import android.location.Location;

import com.google.openlocationcode.OpenLocationCode;
import com.google.openlocationcode.OpenLocationCode.CodeArea;

import com.openlocationcode.android.code.OpenLocationCodeUtil;

/**
 * Util functions related to direction.
 */
public class DirectionUtil {

    /**
     * This computes a direction between {@code fromLocation} and a
     * {@code destinationCode}. The computation is done using
     * {@link Location#distanceBetween(double, double, double, double, float[])}.
     *
     * @param fromLocation    The user position.
     * @param destinationCode The code to compute the direction to.
     * @return the {@link Direction}
     */
    public static Direction getDirection(Location fromLocation, OpenLocationCode destinationCode) {
        CodeArea destinationArea = destinationCode.decode();
        double toLatitude = destinationArea.getCenterLatitude();
        double toLongitude = destinationArea.getCenterLongitude();
        float[] results = new float[3];
        Location.distanceBetween(
                fromLocation.getLatitude(),
                fromLocation.getLongitude(),
                toLatitude,
                toLongitude,
                results);

        // The device bearing in the location object is 0-360, the value returned from
        // distanceBetween is -180 to 180. Adjust the device bearing to be in the same range.
        float deviceBearing = fromLocation.getBearing();
        if (deviceBearing > 180) {
            deviceBearing = deviceBearing - 360;
        }

        // Compensate the initial bearing for the device bearing.
        results[1] = results[1] - deviceBearing;
        if (results[1] > 180) {
            results[1] = -360 + results[1];
        } else if (results[1] < -180) {
            results[1] = 360 + results[1];
        }
        return new Direction(
                OpenLocationCodeUtil.createOpenLocationCode(
                        fromLocation.getLatitude(), fromLocation.getLongitude()),
                destinationCode,
                results[0],
                results[1]);
    }

}
