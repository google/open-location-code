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

package com.openlocationcode.android.main;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

import com.google.android.gms.maps.MapView;
import com.google.android.gms.maps.model.CameraPosition;
import com.openlocationcode.android.R;
import com.openlocationcode.android.code.CodeView;
import com.openlocationcode.android.direction.DirectionView;
import com.openlocationcode.android.map.MyMapView;
import com.openlocationcode.android.search.SearchView;

/**
 * The home {@link android.app.Activity}. All features are implemented in this Activity. The
 * features with a UI are code, direction, map, and search. Additionally, the app also obtains the
 * current location of the user.
 * <p />
 * The UI features all live in their own package, with a Contract interface defining the methods on
 * their view(s) and their action listeners. The action listener interface is implemented via a
 * feature Presenter, and the view interface via a {@link android.view.View}.
 * <br />
 * Note that some features have a source and target view, the source view being the UI that the
 * user interacts with for that feature, and the target view being a view that needs to update its
 * data based on an action in that feature (eg Search result).
 * <p />
 * The MainActivity also has a presenter, the {@link MainPresenter}, which implements the user
 * location feature. As some features need to know the user location and the app consists of one
 * Activity only, the {@link MainPresenter} is made accessible to the other features via a static
 * reference.
 */
public class MainActivity extends FragmentActivity {

    private static final String TAG = MainActivity.class.getSimpleName();

    private static final String MAP_CAMERA_POSITION_LATITUDE = "map_camera_position_latitude";

    private static final String MAP_CAMERA_POSITION_LONGITUDE = "map_camera_position_longitude";

    private static final String MAP_CAMERA_POSITION_ZOOM = "map_camera_position_zoom";

    private static final String URI_QUERY_SEPARATOR = "q=";

    private static final String URI_ZOOM_SEPARATOR = "&";

    /**
     * As all features are implemented in this activity, a static {@link MainPresenter} allows all
     * features to access its data without passing a reference to it to each feature presenter.
     */
    private static MainPresenter mMainPresenter;

    // We need to store this because we need to call this at different point in the lifecycle
    private MapView mMapView;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main_act);
        MyMapView myMapView = (MyMapView) findViewById(R.id.myMapView);
        mMapView = myMapView.getMapView();
        mMainPresenter =
                new MainPresenter(
                        this,
                        (SearchView) findViewById(R.id.searchView),
                        (DirectionView) findViewById(R.id.directionView),
                        (CodeView) findViewById(R.id.codeView),
                        myMapView);

        mMapView.onCreate(savedInstanceState);

        // Adjust the map controls and search box top margins to account for the translucent status
        // bar.
        int statusBarHeight = getStatusBarHeight(this);
        LinearLayout mapControl = (LinearLayout) findViewById(R.id.mapControls);
        FrameLayout.LayoutParams mapParams =
                (FrameLayout.LayoutParams) mapControl.getLayoutParams();
        mapParams.topMargin = mapParams.topMargin + statusBarHeight;
        mapControl.setLayoutParams(mapParams);

        RelativeLayout searchBox = (RelativeLayout) findViewById(R.id.searchBox);
        FrameLayout.LayoutParams searchParams =
                (FrameLayout.LayoutParams) searchBox.getLayoutParams();
        searchParams.topMargin = searchParams.topMargin + statusBarHeight;
        searchBox.setLayoutParams(searchParams);

        if (getIntent() != null && Intent.ACTION_VIEW.equals(getIntent().getAction())) {
            handleGeoIntent(getIntent());
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        mMapView.onResume();

        mMainPresenter.loadCurrentLocation();
    }

    @Override
    public void onPause() {
        super.onPause();

        mMapView.onPause();

        mMainPresenter.stopListeningForLocation();
    }

    @Override
    protected void onSaveInstanceState(Bundle savedInstanceState) {
        CameraPosition currentMapCameraPosition = mMainPresenter.getMapCameraPosition();
        Log.i(TAG, "Saving state");
        if (currentMapCameraPosition != null) {
            savedInstanceState.putDouble(
                    MAP_CAMERA_POSITION_LATITUDE, currentMapCameraPosition.target.latitude);
            savedInstanceState.putDouble(
                    MAP_CAMERA_POSITION_LONGITUDE, currentMapCameraPosition.target.longitude);
            savedInstanceState.putFloat(MAP_CAMERA_POSITION_ZOOM, currentMapCameraPosition.zoom);
        }

        super.onSaveInstanceState(savedInstanceState);
    }

    @Override
    public void onRestoreInstanceState(Bundle savedInstanceState) {
        super.onRestoreInstanceState(savedInstanceState);
        Log.i(TAG, "Restoring state");
        if (savedInstanceState != null) {
            double mapCameraPositionLatitude =
                    savedInstanceState.getDouble(MAP_CAMERA_POSITION_LATITUDE);
            double mapCameraPositionLongitude =
                    savedInstanceState.getDouble(MAP_CAMERA_POSITION_LONGITUDE);
            float mapCameraPositionZoom = savedInstanceState.getFloat(MAP_CAMERA_POSITION_ZOOM);
            mMainPresenter.setMapCameraPosition(
                    mapCameraPositionLatitude, mapCameraPositionLongitude, mapCameraPositionZoom);
        }
    }

    /**
     * Handles intent URIs, extracts the query part and sends it to the search function.
     * <p/>
     * URIs may be of the form:
     * <ul>
     * <li>{@code geo:37.802,-122.41962}
     * <li>{@code geo:37.802,-122.41962?q=7C66CM4X%2BC34&z=20}
     * <li>{@code geo:0,0?q=WF59%2BX67%20Praia}
     * </ul>
     * <p/>
     * Only the query string is used. Coordinates and zoom level are ignored. If the query string
     * is not recognised by the search function (say, it's a street address), it will fail.
     */
    private void handleGeoIntent(Intent intent) {
        Uri uri = intent != null ? intent.getData() : null;
        if (uri == null) {
            return;
        }
        String schemeSpecificPart = uri.getEncodedSchemeSpecificPart();
        if (schemeSpecificPart == null || schemeSpecificPart.isEmpty()) {
            return;
        }
        // Get everything after q=
        int queryIndex = schemeSpecificPart.indexOf(URI_QUERY_SEPARATOR);
        if (queryIndex == -1) {
            return;
        }
        String searchQuery = schemeSpecificPart.substring(queryIndex + 2);
        if (searchQuery.contains(URI_ZOOM_SEPARATOR)) {
            searchQuery = searchQuery.substring(0, searchQuery.indexOf(URI_ZOOM_SEPARATOR));
        }
        final String searchString = Uri.decode(searchQuery);
        Log.i(TAG, "Search string is " + searchString);

        // Give the map some time to get ready.
        Handler h = new Handler();
        Runnable r = new Runnable() {
            @Override
            public void run() {
                if (mMainPresenter.getSearchActionsListener().searchCode(searchString)) {
                    mMainPresenter.getSearchActionsListener().setSearchText(searchString);
                }
            }
        };
        h.postDelayed(r, 2000);
    }

    public static MainPresenter getMainPresenter() {
        return mMainPresenter;
    }

    // A method to find height of the status bar
    public static int getStatusBarHeight(Context context) {
        int result = 0;
        int resourceId = context.getResources().getIdentifier(
                "status_bar_height", "dimen", "android");
        if (resourceId > 0) {
            result = context.getResources().getDimensionPixelSize(resourceId);
        }
        return result;
    }

}
