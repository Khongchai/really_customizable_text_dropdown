import 'dart:math';

import "package:flutter/material.dart";
import 'package:modular_customizable_dropdown/classes_and_enums/dropdown_scrollbar_style.dart';
import 'package:modular_customizable_dropdown/classes_and_enums/dropdown_value.dart';
import 'package:modular_customizable_dropdown/utils/delayed_action.dart';
import 'package:modular_customizable_dropdown/utils/filter_out_values_that_do_not_match_query_string.dart';

class AnimatedListView extends StatefulWidget {
  final List<DropdownValue> allDropdownValues;
  final String queryString;
  final Widget Function(DropdownValue dropdownValue, int index) listBuilder;

  ///The alignment is used to calculate the center point for the animated
  ///height transition.
  ///
  /// For example, if the y alignment is DropdownAlignment.center,
  /// the dropdown should begin its animation at the center and expand upward and downward.
  ///
  /// If the alignment is DropdownAlignment.bottomCenter, bottomLeft, or bottomRight,
  /// the animation should begin from the y == 0 position of the dropdown and expand its height downward.
  final Alignment dropdownAlignment;

  ///Height to animate to
  final double expectedDropdownHeight;

  /// List of height for each of the tiles.
  ///
  /// Each tile's height may vary due to the length of the value and description,
  /// so wee ned all of them to determine the final size of our dropdown.
  final List<double> listOfTileHeights;
  final double targetWidth;
  final List<BoxShadow> boxShadows;
  final Color borderColor;
  final double borderThickness;
  final BorderRadius borderRadius;
  final Duration animationDuration;
  final Curve animationCurve;
  final DropdownScrollbarStyle dropdownScrollbarStyle;

  /// For testing the final visible height of the dropdown.
  @visibleForTesting
  final Key? listviewKey;

  const AnimatedListView(
      {required this.allDropdownValues,
      required this.animationDuration,
      required this.animationCurve,
      required this.queryString,
      required this.listBuilder,
      required this.expectedDropdownHeight,
      required this.targetWidth,
      required this.dropdownAlignment,
      required this.borderColor,
      required this.borderRadius,
      required this.borderThickness,
      required this.boxShadows,
      required this.listOfTileHeights,
      required this.dropdownScrollbarStyle,
      this.listviewKey,
      Key? key})
      : super(key: key);

  @override
  State<AnimatedListView> createState() => _AnimatedListViewState();
}

class _AnimatedListViewState extends State<AnimatedListView> {
  double _maxHeight = 0;
  late Duration _animationDuration;
  late final double _animationStartPosition;

  /// This is to ensure that we always get the correct height of the element, say
  /// the original array is [how, are, you]
  /// if the input is "yo", the output array will be [you]
  ///
  /// we then should get the height for the "you" element.
  final Map<String, double> _valuesAndHeightMap = {};

  @override
  void initState() {
    assert(widget.listOfTileHeights.isNotEmpty);
    assert(widget.listOfTileHeights.length == widget.allDropdownValues.length);

    _animationStartPosition = min(max(widget.dropdownAlignment.y, -1), 1) * -1;
    _animationDuration = widget.animationDuration;
    delayedAction(0, () {
      setState(() {
        _maxHeight = widget.expectedDropdownHeight;

        ///Set the animation duration to 0 after the transition in is finished.
        delayedAction(widget.animationDuration.inMilliseconds, () {
          // To prevent setState() after state disposed
          if (mounted) {
            setState(() {
              _animationDuration = const Duration(milliseconds: 0);
            });
          }
        });
      });
    });

    for (int i = 0; i < widget.allDropdownValues.length; i++) {
      _valuesAndHeightMap[widget.allDropdownValues[i].value] =
          widget.listOfTileHeights[i];
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filteredValues = filterOutValuesThatDoNotMatchQueryString(
      queryString: widget.queryString,
      valuesToFilter: widget.allDropdownValues,
    );

    if (filteredValues.isEmpty) return const SizedBox();

    final wrapperStaticHeight = _maxHeight;
    final animatedListHeight = min(
        filteredValues
            .map((e) => _valuesAndHeightMap[e.value]!)
            .toList()
            .sublist(0, filteredValues.length)
            .reduce((value, element) => value + element),
        wrapperStaticHeight);

    return SizedBox(
      key: widget.listviewKey,
      height: wrapperStaticHeight,
      child: Stack(
        alignment: AlignmentDirectional(0, _animationStartPosition),
        children: [
          AnimatedContainer(
            curve: widget.animationCurve,
            duration: _animationDuration,
            height: animatedListHeight,
            width: widget.targetWidth,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: widget.boxShadows,
            ),
            child: Material(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: widget.borderRadius,
                  side: BorderSide(
                    width: widget.borderThickness,
                    style: BorderStyle.solid,
                    color: widget.borderColor,
                  )),
              color: Colors.transparent,
              elevation: 0,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: RawScrollbar(
                  thickness: widget.dropdownScrollbarStyle.thickness,
                  radius: widget.dropdownScrollbarStyle.radius,
                  isAlwaysShown: widget.dropdownScrollbarStyle.isAlwaysShown,
                  interactive: widget.dropdownScrollbarStyle.interactive,
                  minThumbLength: widget.dropdownScrollbarStyle.minThumbLength,
                  thumbColor: widget.dropdownScrollbarStyle.thumbColor,
                  child: ListView.builder(
                      itemCount: filteredValues.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) =>
                          widget.listBuilder(filteredValues[index], index)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
