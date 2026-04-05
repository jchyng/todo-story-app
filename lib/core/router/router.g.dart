// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingCompleteHash() =>
    r'd257bb1d9a2d5c577a0fd39e19e6e29ab3a6c30e';

/// 온보딩 완료 여부 — Firestore users/{uid}.onboarding.googleTasksImportSeen
///
/// null: 로딩 중 또는 미로그인 (리다이렉트 판단 보류)
///
/// Copied from [onboardingComplete].
@ProviderFor(onboardingComplete)
final onboardingCompleteProvider = AutoDisposeStreamProvider<bool?>.internal(
  onboardingComplete,
  name: r'onboardingCompleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingCompleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OnboardingCompleteRef = AutoDisposeStreamProviderRef<bool?>;
String _$routerHash() => r'64386839865f12b1f138d8827d7a7354586cdf4a';

/// See also [router].
@ProviderFor(router)
final routerProvider = AutoDisposeProvider<GoRouter>.internal(
  router,
  name: r'routerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$routerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RouterRef = AutoDisposeProviderRef<GoRouter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
