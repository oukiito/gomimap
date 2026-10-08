// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

/// Bind the external selector to the existing action and spoken information.
/// This wrapper is for a single action, never a card with multiple controls.
Widget identifiedAction(String identifier, Widget child) => MergeSemantics(
  child: Semantics(identifier: identifier, child: child),
);
