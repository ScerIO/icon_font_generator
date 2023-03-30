## 4.0.0

* Rewrite by fork [[fontify]](https://github.com/westracer/fontify)

## 3.2.0

* Can be access to icon by name in String and access to icon name 
```dart
// Return String "account"
UiIcons.account.name;

// Return _UiIconsData? instance
// Attention! Can be null if generated icons font outdated 
final icon = UiIcons.all['collection'];
```

## 3.1.0

* Replace pedantic with lints
* Add naming strategy option namely - snake, camel
* Fixed iconsMap hardcoded `ui_icons.json` which prevented custom out-font name

## 3.0.0

* Replaced [icon-font-generator] with [fantasticon] [pull#14](https://github.com/rbcprolabs/icon_font_generator/pull/14)
* Attribute ascent replaced by descent
* Attribute mono removed
* Attribute yarn added
* Added const in dart class template [issue#16](https://github.com/rbcprolabs/icon_font_generator/issues/16)
* Upgrade dependencies

## 2.0.0

* Null-safety

## 1.0.0

* Added new flag `normalize` - Normalize icons sizes (Default: false) 
* Fixed bug, when an error occurs and the conversion no longer occurs (https://github.com/rbcprolabs/icon_font_generator/issues/3)

## 0.0.7

* Update requirements in readme


## 0.0.6

* Update requirements in readme

## 0.0.5

* Update readme

## 0.0.4

* Readme fix

## 0.0.3

* Hide error message

## 0.0.2

* Fix running as global package

## 0.0.1

* Initial release