/**
 * Platform example — узкий update одного сценария.
 */
async updateMetaProcessed(params: UpdateMetaProcessedParams): Promise<void> {
  await this.repository.update(
    { id: params.id },
    {
      processedBy: params.processedBy,
      ...params.processedComment !== undefined && {
        processedComment: params.processedComment,
      },
    },
  );
}
