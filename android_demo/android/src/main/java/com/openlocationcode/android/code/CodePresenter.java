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

import android.content.Intent;
import android.location.Location;
import android.net.Uri;
import android.provider.ContactsContract.Contacts;
import android.provider.ContactsContract.Intents.Insert;
import android.support.v7.widget.PopupMenu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;

import com.openlocationcode.android.R;
import com.openlocationcode.android.direction.Direction;
import com.openlocationcode.android.direction.DirectionUtil;
import com.openlocationcode.android.main.MainActivity;

import com.google.openlocationcode.OpenLocationCode;
import com.google.openlocationcode.OpenLocationCode.CodeArea;

import java.util.Locale;

/**
 * Presents the code information, direction and handles the share menu.
 */
public class CodePresenter
        implements CodeContract.ActionsListener, PopupMenu.OnMenuItemClickListener {

    private static final float MAX_WALKING_MODE_DISTANCE = 3000f; // 3 km

    private final CodeView mView;

    public CodePresenter(CodeView view) {
        mView = view;

        mView.getShareButton()
                .setOnClickListener(
                        new OnClickListener() {
                            @Override
                            public void onClick(View v) {
                                openShareMenu();
                            }
                        });
        mView.getNavigateButton()
                .setOnClickListener(
                        new OnClickListener() {
                            @Override
                            public void onClick(View v) {
                                navigate();
                            }
                        });
    }

    @Override
    public Direction codeLocationUpdated(double latitude, double longitude, boolean isCurrent) {
        OpenLocationCode code = OpenLocationCodeUtil.createOpenLocationCode(latitude, longitude);
        mView.displayCode(code);
        Location currentLocation = MainActivity.getMainPresenter().getCurrentLocation();

        Direction direction;
        if (isCurrent) {
            direction = new Direction(code, null, 0, 0);
        } else if (currentLocation == null) {
            direction = new Direction(null, code, 0, 0);
        } else {
            direction = DirectionUtil.getDirection(currentLocation, code);
        }

        return direction;
    }

    @Override
    public OpenLocationCode getCurrentOpenLocationCode() {
        return mView.getLastFullCode();
    }

    @Override
    public boolean onMenuItemClick(MenuItem item) {
        int itemId = item.getItemId();
        String code = mView.getCodeAndLocality();
        if (itemId == R.id.share_code) {
            openShareChooser(code);
            return true;
        } else if (itemId == R.id.save_to_contact) {
            saveCodeAsContact(code);
            return true;
        }
        return false;
    }

    private void openShareMenu() {
        PopupMenu popup = new PopupMenu(mView.getContext(), mView.getShareButton());
        popup.setOnMenuItemClickListener(this);
        MenuInflater inflater = popup.getMenuInflater();
        inflater.inflate(R.menu.share_menu, popup.getMenu());
        popup.show();
    }

    private void openShareChooser(String code) {
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.putExtra(Intent.EXTRA_TEXT, code);
        intent.setType("text/plain");
        mView.getContext()
                .startActivity(
                    Intent.createChooser(
                        intent,
                        mView.getContext().getResources().getText(R.string.share_chooser_title)));
    }

    private void saveCodeAsContact(String code) {
        Intent intent = new Intent(Intent.ACTION_INSERT_OR_EDIT);
        intent.setType(Contacts.CONTENT_ITEM_TYPE);
        intent.putExtra(Insert.POSTAL, code);
        mView.getContext().startActivity(intent);
    }

    private void navigate() {
        OpenLocationCode code = mView.getLastFullCode();
        CodeArea codeArea = code.decode();
        Location currentLocation = MainActivity.getMainPresenter().getCurrentLocation();
        float[] results = new float[3];
        Location.distanceBetween(
                currentLocation.getLatitude(),
                currentLocation.getLongitude(),
                codeArea.getCenterLatitude(),
                codeArea.getCenterLongitude(),
                results);
        float distance = results[0];
        char navigationMode;
        if (distance <= MAX_WALKING_MODE_DISTANCE) {
            navigationMode = 'w';
        } else {
            navigationMode = 'd';
        }

        Uri gmmIntentUri = Uri.parse(
                String.format(
                        Locale.US,
                        "google.navigation:q=%f,%f&mode=%s",
                        codeArea.getCenterLatitude(),
                        codeArea.getCenterLongitude(),
                        navigationMode));
        Intent mapIntent = new Intent(Intent.ACTION_VIEW, gmmIntentUri);
        mView.getContext().startActivity(mapIntent);
    }
}
