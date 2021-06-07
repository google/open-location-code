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

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout.LayoutParams;

import com.openlocationcode.android.R;


/**
 * Displays a welcome screen if it has not yet been displayed for the current version code.
 */
public class WelcomeActivity extends FragmentActivity {
    private static final String TAG = WelcomeActivity.class.getSimpleName();
    private static final String WELCOME_VERSION_CODE_SHOWN_PREF = "welcome_screen_version_code";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
        // Second argument is the default to use if the preference can't be found
        int savedVersionCode = prefs.getInt(WELCOME_VERSION_CODE_SHOWN_PREF, 0);
        int appVersionCode = 0;
        try {
            appVersionCode = getPackageManager().getPackageInfo(getPackageName(), 0).versionCode;
        } catch (NameNotFoundException nnfe) {
            Log.w(TAG, "Exception getting appVersionCode : " + nnfe);
        }

        final Intent intent = new Intent(this, MainActivity.class);
        final Activity activity = this;

        if (appVersionCode == savedVersionCode) {
            activity.startActivity(intent);
            activity.finish();
        } else {
            Log.i(TAG, "Starting welcome page");
            setContentView(R.layout.welcome);

            // Increase the margin on the image to account for the translucent status bar.
            ImageView welcomeImage = (ImageView) findViewById(R.id.welcome_image);
            LayoutParams layoutParams = (LayoutParams) welcomeImage.getLayoutParams();
            layoutParams.topMargin = layoutParams.topMargin + MainActivity.getStatusBarHeight(this);
            welcomeImage.setLayoutParams(layoutParams);

            Button button = (Button) findViewById(R.id.welcome_button);
            button.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    activity.startActivity(intent);
                    activity.finish();
                }
            });

            SharedPreferences.Editor editor = prefs.edit();
            editor.putInt(WELCOME_VERSION_CODE_SHOWN_PREF, appVersionCode);
            editor.apply();
        }
    }
}
