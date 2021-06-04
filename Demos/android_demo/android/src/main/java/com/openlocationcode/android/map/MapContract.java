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

package com.openlocationcode.android.map;

import android.location.Location;

import com.google.openlocationcode.OpenLocationCode;
import com.google.android.gms.maps.model.CameraPosition;


/**
 * The contract for the map feature.
 */
public interface MapContract {

    interface View {

        void moveMapToLocation(OpenLocationCode code);

        void drawCodeArea(OpenLocationCode code);

        void showSatelliteView();

        void showRoadView();

        void setListener(ActionsListener listener);

        CameraPosition getCameraPosition();

        void setCameraPosition(double latitude, double longitude, float zoom);

        void stopUpdateCodeOnDrag();

        void startUpdateCodeOnDrag();
    }

    interface ActionsListener {

        void mapChanged(double latitude, double longitude);

        void requestSatelliteView();

        void requestRoadView();

        void moveMapToLocation(Location location);

        CameraPosition getMapCameraPosition();

        void setMapCameraPosition(double latitude, double longitude, float zoom);

        /**
         * Call this to stop updating the code feature on dragging the map. This is used by the
         * search feature, ie make sure the search result is shown and not cancelled by dragging
         * the map.
         */
        void stopUpdateCodeOnDrag();

        /**
         * Call this to start updating the code feature on dragging the map, eg when search is
         * cancelled.
         */
        void startUpdateCodeOnDrag();
    }

}
