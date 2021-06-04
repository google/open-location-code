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

import android.content.Context;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.openlocationcode.android.R;

public class DirectionView extends LinearLayout implements DirectionContract.View {

    private static final long ANIMATION_DURATION_MS = 500;

    // Gives the current heading of the direction indicator.
    // This is continuous with 0 as north and 180/-180 as south.
    // This avoids the animation "spinning" when crossing a boundary.
    private float mDirectionCurrentRotation = 0f;

    public DirectionView(Context context, AttributeSet attrs) {
        super(context, attrs);
        LayoutInflater inflater;
        inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        inflater.inflate(R.layout.direction, this, true);
    }

    @Override
    public void showDirection(float degreesFromNorth) {
        ImageView iv = (ImageView) findViewById(R.id.direction_indicator);
        float correctedCurrent = ((180 + mDirectionCurrentRotation) % 360) - 180;
        if (correctedCurrent < -180) {
            correctedCurrent = 360 + correctedCurrent;
        } else if (correctedCurrent > 180) {
            correctedCurrent = correctedCurrent - 360;
        }

        float relativeRotation = degreesFromNorth - correctedCurrent;
        if (relativeRotation < -180) {
            relativeRotation = 360 + relativeRotation;
        } else if (relativeRotation > 180) {
            relativeRotation = -360 + relativeRotation;
        }
        mDirectionCurrentRotation = mDirectionCurrentRotation + relativeRotation;
        iv.animate().rotation(mDirectionCurrentRotation).setDuration(ANIMATION_DURATION_MS).start();
    }

    @Override
    public void showDistance(int distanceInMeters) {
        TextView tv = (TextView) findViewById(R.id.distance);

        if (distanceInMeters < 1000) {
            tv.setText(String.format(getResources().getString(R.string.distance_meters),
                    distanceInMeters));
        } else if (distanceInMeters < 3000) {
            double distanceInKm = distanceInMeters / 1000.0;
            tv.setText(String.format(getResources().getString(R.string.distance_few_kilometers),
                    distanceInKm));
        } else {
            double distanceInKm = distanceInMeters / 1000.0;
            tv.setText(String.format(getResources().getString(R.string.distance_many_kilometers),
                    distanceInKm));
        }
    }

}
