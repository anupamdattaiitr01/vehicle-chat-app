import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/overlay_service.dart';
import '../../domain/entities/booking_entity.dart';

class BookingException implements Exception {
  final String message;
  const BookingException(this.message);
}

abstract class BookingRemoteDataSource {
  Future<List<BookingEntity>> fetchMyBookings();
  Future<BookingEntity> respondToBooking({
    required String bookingId,
    required String action,
    String? queryText,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final DioClient _dioClient;

  BookingRemoteDataSourceImpl(this._dioClient) {
    OverlayService.cacheBaseUrl(_dioClient.dio.options.baseUrl);
  }

  @override
  Future<List<BookingEntity>> fetchMyBookings() async {
    try {
      // Re-sync baseUrl + JWT after login so native WindowManager card can confirm rides in kill mode
      await OverlayService.cacheBaseUrl(_dioClient.dio.options.baseUrl);

      final response = await _dioClient.dio.get(
        '${AppConstants.bookingsEndpoint}/my-bookings',
      );
      final list = response.data as List<dynamic>;
      return list
          .whereType()
          .map((item) => BookingEntity.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw BookingException(
        DioClient.extractErrorMessage(e, fallback: 'Failed to load bookings.'),
      );
    }
  }

  @override
  Future<BookingEntity> respondToBooking({
    required String bookingId,
    required String action,
    String? queryText,
  }) async {
    try {
      final response = await _dioClient.dio.patch(
        '${AppConstants.bookingsEndpoint}/$bookingId/respond',
        data: {
          'action': action,
          if (queryText != null && queryText.trim().isNotEmpty)
            'queryText': queryText.trim(),
        },
      );
      return BookingEntity.fromMap(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e) {
      throw BookingException(
        DioClient.extractErrorMessage(
          e,
          fallback: 'Failed to submit booking response.',
        ),
      );
    }
  }
}