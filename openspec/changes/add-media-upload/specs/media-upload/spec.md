## ADDED Requirements

### Requirement: Authenticated image upload
The system SHALL accept an image via `POST /media/images` (multipart field `file`) from an authenticated user holding `profiles:update_own`, store it in the configured object storage, and return its public `url`, `contentType` and `size`.

#### Scenario: Valid image
- **WHEN** an authenticated user uploads a JPEG, PNG or WebP of at most 5 MB
- **THEN** the system responds 201 with a storage `url` under `images/<userId>/`

#### Scenario: Unauthenticated upload
- **WHEN** a request without a valid token is sent
- **THEN** the system responds 401

### Requirement: Uploads are validated by content
The system MUST determine the image type from the file signature, not from the client-supplied content type or file name, and MUST generate the storage key itself.

#### Scenario: Non-image with image header
- **WHEN** a file whose bytes are not JPEG, PNG or WebP is uploaded with `Content-Type: image/jpeg`
- **THEN** the system responds 400 with `code: IMAGE_UNSUPPORTED_TYPE` and stores nothing

#### Scenario: File too large
- **WHEN** the file exceeds 5 MB
- **THEN** the system responds 413 and stores nothing

#### Scenario: Missing file
- **WHEN** the multipart body has no `file` field
- **THEN** the system responds 400 with `code: IMAGE_MISSING`

### Requirement: Storage is replaceable
Domain code SHALL depend on the `StoragePort` interface only; the S3/MinIO implementation is configured via `S3_*` environment variables. When they are missing, uploads respond 503 `STORAGE_NOT_CONFIGURED` while the rest of the API keeps working.

#### Scenario: Storage not configured
- **WHEN** an upload is requested and `S3_*` variables are not set
- **THEN** the system responds 503 with `code: STORAGE_NOT_CONFIGURED`
