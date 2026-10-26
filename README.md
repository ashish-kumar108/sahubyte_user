# Sahubyte User

Customer-facing Flutter application for booking hardware and software repair services. Users can raise an enquiry, choose device and problem details, attach supporting files, share a service location and follow the job through completion.

## Product flow

- Mobile authentication and account onboarding
- Device brand, category and issue selection
- Service enquiry creation and status tracking
- Location capture with maps and geocoding
- File attachments and downloadable job documents
- Job card, parts and service summary views
- Persistent sessions and REST API integration

## Engineering highlights

- MVVM-style separation across views, view models, repositories and network services
- Reusable API response and exception handling
- Responsive Flutter UI for Android, web and desktop targets
- Local persistence with `shared_preferences`
- Maps, location, PDF and file workflows

## Tech stack

Flutter, Dart, REST APIs, HTTP, Shared Preferences, Flutter Map, Geolocator, Geocoding, File Picker and PDF.

## Related application

The connected service-provider workflow is available in [Sahubyte Vendor](https://github.com/ashish-kumar108/sahubyte_vendor).

## Note

This repository demonstrates the Flutter client architecture and product workflow. A compatible backend service is required for live data.
