/*
 * OPEN-XCHANGE legal information
 *
 * All intellectual property rights in the Software are protected by
 * international copyright laws.
 *
 *
 * In some countries OX, OX Open-Xchange and open xchange
 * as well as the corresponding Logos OX Open-Xchange and OX are registered
 * trademarks of the OX Software GmbH group of companies.
 * The use of the Logos is not covered by the Mozilla Public License 2.0 (MPL 2.0).
 * Instead, you are allowed to use these Logos according to the terms and
 * conditions of the Creative Commons License, Version 2.5, Attribution,
 * Non-commercial, ShareAlike, and the interpretation of the term
 * Non-commercial applicable to the aforementioned license is published
 * on the web site https://www.open-xchange.com/terms-and-conditions/.
 *
 * Please make sure that third-party modules and libraries are used
 * according to their respective licenses.
 *
 * Any modifications to this package must retain all copyright notices
 * of the original copyright holder(s) for the original code used.
 *
 * After any such modifications, the original and derivative code shall remain
 * under the copyright of the copyright holder(s) and/or original author(s) as stated here:
 * https://www.open-xchange.com/legal/. The contributing author shall be
 * given Attribution for the derivative code and a license granting use.
 *
 * Copyright (C) 2016-2020 OX Software GmbH
 * Mail: info@open-xchange.com
 *
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the Mozilla Public License 2.0
 * for more details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:ox_coi/src/brandable/custom_theme.dart';
import 'package:ox_coi/src/extensions/string_ui.dart';
import 'package:ox_coi/src/l10n/l.dart';
import 'package:ox_coi/src/l10n/l10n.dart';
import 'package:ox_coi/src/navigation/navigatable.dart';
import 'package:ox_coi/src/navigation/navigation.dart';
import 'package:ox_coi/src/qr/qr_bloc.dart';
import 'package:ox_coi/src/qr/qr_event_state.dart';
import 'package:ox_coi/src/ui/dimensions.dart';
import 'package:ox_coi/src/user/user_bloc.dart';
import 'package:ox_coi/src/user/user_event_state.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShowQr extends StatefulWidget {
  final int _chatId;

  ShowQr(this._chatId);

  @override
  _ShowQrState createState() => _ShowQrState();
}

class _ShowQrState extends State<ShowQr> {
  final _logger = Logger("show_qr");
  final UserBloc _userBloc = UserBloc();
  final QrBloc _qrBloc = QrBloc();
  final Navigation _navigation = Navigation();
  String _qrText;

  @override
  void initState() {
    super.initState();
    _navigation.current = Navigatable(Type.showQr);
    _qrBloc.add(RequestQrText(chatId: widget._chatId));
    _userBloc.add(RequestUser());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: dimension20dp),
          child: buildQrCodeArea(),
        ),
        buildInfoText(),
      ],
    );
  }

  Widget buildInfoText() {
    return BlocBuilder(
        bloc: _userBloc,
        builder: (context, state) {
          if (state is UserStateSuccess) {
            return Padding(
              padding: const EdgeInsets.all(dimension8dp),
              child: Text(
                L10n.getFormatted(L.qrScanTextX, [state.config.email]),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return Container();
          }
        });
  }

  Widget buildQrCodeArea() {
    return BlocBuilder(
      bloc: _qrBloc,
      builder: (context, state) {
        if (state is QrStateSuccess) {
          if (state.qrText != null && state.qrText.isNotEmpty) {
            _qrText = state.qrText;
          }
          return buildQrCode(_qrText);
        } else if (state is QrStateLoading) {
          L10n.get(L.contactVerificationRunning).showToast();
          return buildQrCode(_qrText);
        } else if (state is QrStateVerificationFinished) {
          L10n.get(L.contactVerificationFinished).showToast();
          return buildQrCode(_qrText);
        } else if (state is QrStateFailure) {
          state.error.showToast();
          return buildQrCode(_qrText);
        } else {
          return Container();
        }
      },
    );
  }

  Widget buildQrCode(String qrText) {
    return QrImage(
      data: qrText,
      size: qrImageSize,
      backgroundColor: CustomTheme.of(context).white,
      version: 8,
      errorStateBuilder: (context, error) {
        _logger.info(L10n.getFormatted(L.qrShowErrorX, [error]));
        return Container(
          child: Center(
            child: Text(
              L10n.getFormatted(L.qrShowErrorX, [error]),
              style: Theme.of(context).textTheme.body2.apply(color: CustomTheme.of(context).error),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
