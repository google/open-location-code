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
import android.location.Location;
import android.util.Log;
import android.widget.Toast;

import com.google.android.gms.maps.model.CameraPosition;
import com.openlocationcode.android.R;
import com.openlocationcode.android.code.CodeContract;
import com.openlocationcode.android.code.CodePresenter;
import com.openlocationcode.android.code.CodeView;
import com.openlocationcode.android.current.DaggerLocationProviderFactoryComponent;
import com.openlocationcode.android.current.GoogleApiModule;
import com.openlocationcode.android.current.LocationProvider;
import com.openlocationcode.android.current.LocationProvider.LocationCallback;
import com.openlocationcode.android.current.LocationProviderFactoryComponent;
import com.openlocationcode.android.direction.Direction;
import com.openlocationcode.android.direction.DirectionContract;
import com.openlocationcode.android.direction.DirectionPresenter;
import com.openlocationcode.android.direction.DirectionUtil;
import com.openlocationcode.android.direction.DirectionView;
import com.openlocationcode.android.map.MapContract;
import com.openlocationcode.android.map.MapPresenter;
import com.openlocationcode.android.map.MyMapView;
import com.openlocationcode.android.search.SearchContract;
import com.openlocationcode.android.search.SearchContract.TargetView;
import com.openlocationcode.android.search.SearchPresenter;
import com.openlocationcode.android.search.SearchView;

import java.util.ArrayList;
import java.util.List;

import com.google.openlocationcode.OpenLocationCode;

/**
 * This Presenter takes care of obtaining the user current location, as well as synchronising data
 * between all the features: search, code, direction, and map.
 */
public class MainPresenter implements LocationCallback {

    private static final String TAG = MainPresenter.class.getSimpleName();

    private final SearchContract.ActionsListener mSearchActionsListener;

    private final CodeContract.ActionsListener mCodeActionsListener;

    private final DirectionContract.ActionsListener mDirectionActionsListener;

    private final MapContract.ActionsListener mMapActionsListener;

    private final Context mContext;

    private final LocationProvider mLocationProvider;

    private Location mCurrentLocation;

    public MainPresenter(
            Context context,
            SearchView searchView,
            DirectionView directionView,
            CodeView codeView,
            MyMapView mapView) {
        List<TargetView> searchTargetViews = new ArrayList<>();
        searchTargetViews.add(codeView);
        searchTargetViews.add(mapView);
        mContext = context;
        mSearchActionsListener = new SearchPresenter(searchView, searchTargetViews);
        searchView.setActionsListener(mSearchActionsListener);
        mDirectionActionsListener = new DirectionPresenter(directionView);
        mCodeActionsListener = new CodePresenter(codeView);
        mMapActionsListener =
                new MapPresenter(mapView, mCodeActionsListener, mDirectionActionsListener);
        mapView.setListener(mMapActionsListener);

        LocationProviderFactoryComponent locationProviderFactoryComponent =
                DaggerLocationProviderFactoryComponent.builder()
                        .googleApiModule(new GoogleApiModule(context))
                        .build();
        mLocationProvider =
                locationProviderFactoryComponent.locationProviderFactory().create(context, this);
    }

    public void loadCurrentLocation() {
        Toast.makeText(
                mContext, mContext.getResources().getString(R.string.current_location_loading),
                Toast.LENGTH_LONG).show();
        mLocationProvider.connect();
    }

    public void currentLocationUpdated(Location location) {
        if (location.hasBearing() && getCurrentOpenLocationCode() != null) {
            Direction direction =
                    DirectionUtil.getDirection(location, getCurrentOpenLocationCode());
            mDirectionActionsListener.directionUpdated(direction);
        }
        if (mCurrentLocation == null) {
            // This is the first location received, so we can move the map to this position.
            mMapActionsListener.setMapCameraPosition(
                    location.getLatitude(), location.getLongitude(), MyMapView.INITIAL_MAP_ZOOM);
        }
        mCurrentLocation = location;
    }

    public void stopListeningForLocation() {
        mLocationProvider.disconnect();
    }

    @Override
    public void handleNewLocation(Location location) {
        Log.i(TAG, "Received new location from LocationProvider: " + location);
        currentLocationUpdated(location);
    }

    @Override
    public void handleNewBearing(float bearing) {
        Log.i(TAG, "Received new bearing from LocationProvider: " + bearing);
        if (mCurrentLocation != null) {
            mCurrentLocation.setBearing(bearing);
            currentLocationUpdated(mCurrentLocation);
        }
    }

    @Override
    public void handleLocationNotAvailable() {
        Toast.makeText(
                mContext,
                mContext.getResources().getString(R.string.current_location_error),
                Toast.LENGTH_LONG)
                .show();
    }

    public Location getCurrentLocation() {
        return mCurrentLocation;
    }

    private OpenLocationCode getCurrentOpenLocationCode() {
        return mCodeActionsListener.getCurrentOpenLocationCode();
    }

    public CameraPosition getMapCameraPosition() {
        return mMapActionsListener.getMapCameraPosition();
    }

    public SearchContract.ActionsListener getSearchActionsListener() {
        return mSearchActionsListener;
    }

    public void setMapCameraPosition(double latitude, double longitude, float zoom) {
        mMapActionsListener.setMapCameraPosition(latitude, longitude, zoom);
    }

    public MapContract.ActionsListener getMapActionsListener() {
        return mMapActionsListener;
    }
}
