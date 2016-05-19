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

package com.openlocationcode.android.current;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.IntentSender;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.util.Log;
import android.view.Display;
import android.view.Surface;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.FusedLocationProviderApi;
import com.google.android.gms.location.LocationAvailability;
import com.google.android.gms.location.LocationRequest;
import com.google.auto.factory.AutoFactory;
import com.google.auto.factory.Provided;

public class LocationProvider
        implements GoogleApiClient.ConnectionCallbacks, GoogleApiClient.OnConnectionFailedListener,
        com.google.android.gms.location.LocationListener, SensorEventListener {

    public interface LocationCallback {

        /**
         * Will never return a null location
         **/
        void handleNewLocation(Location location);

        void handleNewBearing(float bearing);

        void handleLocationNotAvailable();
    }

    private static final String TAG = LocationProvider.class.getSimpleName();

    private static final int CONNECTION_FAILURE_RESOLUTION_REQUEST = 9000;

    private static final int INTERVAL_IN_MS = 10 * 1000;

    private static final int FASTEST_INTERVAL_IN_MS = 1000;

    private static final float MIN_BEARING_DIFF = 2.0f;

    private final GoogleApiAvailability mGoogleApiAvailability;

    private final GoogleApiClient mGoogleApiClient;

    private final FusedLocationProviderApi mFusedLocationProviderApi;

    private final LocationManager mLocationManager;

    private final Context mContext;

    private final LocationCallback mLocationCallback;

    private final LocationRequest mLocationRequest;

    private final LocationListener mNetworkLocationListener;

    private final LocationListener mGpsLocationListener;

    private Location mCurrentBestLocation;

    private boolean mUsingGms = false;

    private final SensorManager mSensorManager;

    private final Display mDisplay;

    private int mAxisX, mAxisY;

    private Float mBearing;

    @AutoFactory
    public LocationProvider(
            @Provided GoogleApiAvailability googleApiAvailability,
            @Provided GoogleApiClient googleApiClient,
            @Provided FusedLocationProviderApi fusedLocationProviderApi,
            @Provided LocationManager locationManager,
            @Provided SensorManager sensorManager,
            @Provided Display displayManager,
            Context context,
            LocationCallback locationCallback) {
        this.mGoogleApiAvailability = googleApiAvailability;
        this.mGoogleApiClient = googleApiClient;
        this.mFusedLocationProviderApi = fusedLocationProviderApi;
        this.mLocationManager = locationManager;
        this.mContext = context;
        this.mLocationCallback = locationCallback;
        this.mSensorManager = sensorManager;
        this.mDisplay = displayManager;
        mLocationRequest =
                LocationRequest.create()
                        .setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY)
                        .setInterval(INTERVAL_IN_MS)
                        .setFastestInterval(FASTEST_INTERVAL_IN_MS);
        mNetworkLocationListener = createLocationListener();
        mGpsLocationListener = createLocationListener();

        determineIfUsingGms();
        if (isUsingGms()) {
            mGoogleApiClient.registerConnectionCallbacks(this);
            mGoogleApiClient.registerConnectionFailedListener(this);
        }
    }

    private boolean isUsingGms() {
        return mUsingGms;
    }

    public void connect() {
        if (isUsingGms()) {
            if (mGoogleApiClient.isConnected()) {
                onConnected(new Bundle());
            } else {
                mGoogleApiClient.connect();
            }
        } else {
            connectUsingOldApi();
        }

        Sensor mSensor = mSensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);
        mSensorManager.registerListener(this, mSensor, SensorManager.SENSOR_DELAY_NORMAL * 5);
    }

    public void disconnect() {
        if (isUsingGms() && mGoogleApiClient.isConnected()) {
            mFusedLocationProviderApi.removeLocationUpdates(mGoogleApiClient, this);
            mGoogleApiClient.disconnect();
        } else if (!isUsingGms()) {
            disconnectUsingOldApi();
        }
        mSensorManager.unregisterListener(this);
    }

    @Override
    public void onConnected(Bundle bundle) {
        Log.i(TAG, "Connected to location services");

        LocationAvailability locationAvailability =
                mFusedLocationProviderApi.getLocationAvailability(mGoogleApiClient);
        if (!locationAvailability.isLocationAvailable()) {
            mLocationCallback.handleLocationNotAvailable();
            return;
        }

        Location lastKnownLocation = mFusedLocationProviderApi.getLastLocation(mGoogleApiClient);
        mFusedLocationProviderApi.requestLocationUpdates(mGoogleApiClient, mLocationRequest, this);
        if (lastKnownLocation != null) {
            Log.i(TAG, "Received last known location: " + lastKnownLocation);
            mCurrentBestLocation = lastKnownLocation;
            if (mBearing != null) {
                mCurrentBestLocation.setBearing(mBearing);
            }
            mLocationCallback.handleNewLocation(mCurrentBestLocation);
        }
    }

    @Override
    public void onConnectionSuspended(int i) {
    }

    @Override
    public void onConnectionFailed(@NonNull ConnectionResult connectionResult) {
        if (connectionResult.hasResolution() && mContext instanceof Activity) {
            try {
                Activity activity = (Activity) mContext;
                connectionResult.startResolutionForResult(
                    activity, CONNECTION_FAILURE_RESOLUTION_REQUEST);
            } catch (IntentSender.SendIntentException e) {
                Log.e(TAG, e.getMessage());
            }
        } else {
            Log.i(
                    TAG,
                    "Location services connection failed with code: "
                            + connectionResult.getErrorCode());
            connectUsingOldApi();
        }
    }

    @Override
    public void onLocationChanged(Location location) {
        if (location == null) {
            return;
        }
        mCurrentBestLocation = location;
        if (mBearing != null) {
            mCurrentBestLocation.setBearing(mBearing);
        }
        mLocationCallback.handleNewLocation(mCurrentBestLocation);
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        if (sensor.getType() == Sensor.TYPE_ROTATION_VECTOR) {
            Log.i(TAG, "Rotation sensor accuracy changed to: " + accuracy);
        }
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        float rotationMatrix[] = new float[16];
        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values);
        float[] orientationValues = new float[3];
        readDisplayRotation();
        SensorManager.remapCoordinateSystem(rotationMatrix, mAxisX, mAxisY, rotationMatrix);
        SensorManager.getOrientation(rotationMatrix, orientationValues);
        double azimuth = Math.toDegrees(orientationValues[0]);
        // Azimuth values are now -180-180 (N=0), but once added to the location object
        // they become 0-360 (N=0).
        @SuppressLint("UseValueOf") Float newBearing = new Float(azimuth);
        if (mBearing == null || Math.abs(mBearing - newBearing) > MIN_BEARING_DIFF) {
            mBearing = newBearing;
            if (mCurrentBestLocation != null) {
                mCurrentBestLocation.setBearing(mBearing);
            }
            mLocationCallback.handleNewBearing(mBearing);
        }
    }

    private void determineIfUsingGms() {
        // Possible returned status codes can be found at
        // https://developers.google.com/android/reference/com/google/android/gms/common/GoogleApiAvailability
        int statusCode = mGoogleApiAvailability.isGooglePlayServicesAvailable(mContext);
        if (statusCode == ConnectionResult.SUCCESS
                || statusCode == ConnectionResult.SERVICE_UPDATING) {
            mUsingGms = true;
        }
    }

    private void connectUsingOldApi() {
        Location lastKnownGpsLocation =
                mLocationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
        Location lastKnownNetworkLocation =
                mLocationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
        Location bestLastKnownLocation = mCurrentBestLocation;
        if (lastKnownGpsLocation != null
                && LocationUtil.isBetterLocation(lastKnownGpsLocation, bestLastKnownLocation)) {
            bestLastKnownLocation = lastKnownGpsLocation;
        }
        if (lastKnownNetworkLocation != null
                && LocationUtil.isBetterLocation(
                        lastKnownNetworkLocation, bestLastKnownLocation)) {
            bestLastKnownLocation = lastKnownNetworkLocation;
        }
        mCurrentBestLocation = bestLastKnownLocation;

        if (mLocationManager.getAllProviders().contains(LocationManager.GPS_PROVIDER)
                && mLocationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
            mLocationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER, FASTEST_INTERVAL_IN_MS, 0.0f,
                    mGpsLocationListener);
        }
        if (mLocationManager.getAllProviders().contains(LocationManager.NETWORK_PROVIDER)
                && mLocationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
            mLocationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER, FASTEST_INTERVAL_IN_MS, 0.0f,
                    mNetworkLocationListener);
        }
        if (bestLastKnownLocation != null) {
            Log.i(TAG, "Received last known location via old API: " + bestLastKnownLocation);
            if (mBearing != null) {
                bestLastKnownLocation.setBearing(mBearing);
            }
            mLocationCallback.handleNewLocation(bestLastKnownLocation);
        }
    }

    private void disconnectUsingOldApi() {
        mLocationManager.removeUpdates(mGpsLocationListener);
        mLocationManager.removeUpdates(mNetworkLocationListener);
    }

    private LocationListener createLocationListener() {
        return new LocationListener() {
            public void onLocationChanged(Location location) {
                if (LocationUtil.isBetterLocation(location, mCurrentBestLocation)) {
                    mCurrentBestLocation = location;
                    if (mBearing != null) {
                        mCurrentBestLocation.setBearing(mBearing);
                    }
                    mLocationCallback.handleNewLocation(location);
                }
            }

            public void onStatusChanged(String provider, int status, Bundle extras) {
            }

            public void onProviderEnabled(String provider) {
            }

            public void onProviderDisabled(String provider) {
            }
        };
    }

    /**
     * Read the screen rotation so we can correct the device heading.
     */
    @SuppressWarnings("SuspiciousNameCombination")
    private void readDisplayRotation() {
        mAxisX = SensorManager.AXIS_X;
        mAxisY = SensorManager.AXIS_Y;
        switch (mDisplay.getRotation()) {
            case Surface.ROTATION_0:
                break;
            case Surface.ROTATION_90:
                mAxisX = SensorManager.AXIS_Y;
                mAxisY = SensorManager.AXIS_MINUS_X;
                break;
            case Surface.ROTATION_180:
                mAxisY = SensorManager.AXIS_MINUS_Y;
                break;
            case Surface.ROTATION_270:
                mAxisX = SensorManager.AXIS_MINUS_Y;
                mAxisY = SensorManager.AXIS_X;
                break;
            default:
                break;
        }
    }
}
