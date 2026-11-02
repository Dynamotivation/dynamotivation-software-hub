// Native diagnostic comparing stock Fluent, Material, and app controls.
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart' as m;

import '../../apps/windows/lib/presentation/widgets/accessible_icon_button.dart';

void main() => m.runApp(
  m.MaterialApp(
    localizationsDelegates: const [f.FluentLocalizations.delegate],
    home: f.FluentTheme(
      data: f.FluentThemeData(brightness: m.Brightness.light),
      child: m.Scaffold(
        body: m.Padding(
          padding: const m.EdgeInsets.all(24),
          child: m.Column(
            crossAxisAlignment: m.CrossAxisAlignment.start,
            children: [
              const m.Text('Stock-control focus comparison'),
              const m.SizedBox(height: 24),
              const m.TextField(
                autofocus: true,
                decoration: m.InputDecoration(labelText: 'Material search'),
              ),
              const m.SizedBox(height: 24),
              const f.TextBox(placeholder: 'Fluent search'),
              const m.SizedBox(height: 24),
              f.Button(onPressed: () {}, child: const m.Text('Fluent action')),
              m.ElevatedButton(
                onPressed: () {},
                child: const m.Text('Material action'),
              ),
              AccessibleIconButton(
                label: 'Custom action',
                icon: const m.Icon(m.Icons.settings),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
