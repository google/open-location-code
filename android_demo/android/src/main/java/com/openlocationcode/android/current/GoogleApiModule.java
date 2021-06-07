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

import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.location.FusedLocationProviderApi;
import com.google.android.gms.location.LocationServices;

import android.content.Context;
import android.hardware.SensorManager;
import android.location.LocationManager;
import android.view.Display;
import android.view.WindowManager;

import dagger.Module;
import dagger.Provides;

import javax.inject.Singleton;

@Module
public class GoogleApiModule {

    private final Context mContext;

    public GoogleApiModule(Context context) {
        this.mContext = context;
    }

    @Provides
    @Singleton
    public GoogleApiClient provideGoogleApiClient() {
        return new GoogleApiClient.Builder(mContext).addApi(LocationServices.API).build();
    }

    @Provides
    @Singleton
    public GoogleApiAvailability provideGoogleApiAvailability() {
        return GoogleApiAvailability.getInstance();
    }

    @SuppressWarnings("SameReturnValue")
    @Provides
    @Singleton
    public FusedLocationProviderApi provideFusedLocationProviderApi() {
        return LocationServices.FusedLocationApi;
    }

    @Provides
    @Singleton
    public LocationManager provideLocationManager() {
        return (LocationManager) mContext.getSystemService(Context.LOCATION_SERVICE);
    }

    @Provides
    @Singleton
    public SensorManager provideSensorManager() {
        return (SensorManager) mContext.getSystemService(Context.SENSOR_SERVICE);
    }

    @Provides
    @Singleton
    public Display provideDisplayManager() {
        return ((WindowManager) mContext.getSystemService(Context.WINDOW_SERVICE))
                .getDefaultDisplay();
    }
}
