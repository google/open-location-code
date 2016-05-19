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

/**
 * The contract for the direction feature. The direction shows the direction (bearing) and the
 * distance of a code, compared to the user current location.
 */
public interface DirectionContract {

    interface View {

        void showDirection(float degreesFromNorth);

        void showDistance(int distanceInMeters);
    }

    interface ActionsListener {

        /**
         * Call this when the user current location or the code currently shown to the user is
         * updated.
         */
        void directionUpdated(Direction direction);
    }

}
