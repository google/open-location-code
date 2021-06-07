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

package com.openlocationcode.android.code;

import com.openlocationcode.android.direction.Direction;

import com.google.openlocationcode.OpenLocationCode;

/**
 * The contract for the functionality displaying the code, in {@link
 * com.openlocationcode.android.main.MainActivity}.
 */
public interface CodeContract {

    interface View {

        /**
         * Implements displaying the {@code code}.
         */
        void displayCode(OpenLocationCode code);
    }

    interface ActionsListener {

        /**
         * Call this when the code is requested for a new location (eg when the map is dragged).
         *
         * @param latitude
         * @param longitude
         * @param isCurrent
         * @return
         */
        Direction codeLocationUpdated(double latitude, double longitude, boolean isCurrent);

        /**
         * @return the code currently displayed to the user.
         */
        OpenLocationCode getCurrentOpenLocationCode();
    }

}
