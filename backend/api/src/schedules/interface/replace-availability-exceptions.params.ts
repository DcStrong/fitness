import type {
  AvailabilityExceptionType,
  AvailabilityExceptionWindowModel,
} from './availability.types';

export interface ReplaceAvailabilityExceptionsParams {
  coachId: string;
  exceptions: Array<{
    localDate: string;
    type: AvailabilityExceptionType;
    windows: AvailabilityExceptionWindowModel[] | null;
  }>;
}
