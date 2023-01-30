CREATE NONCLUSTERED INDEX [IX_SummaryResponses_StartDate_EndDate]
    ON [SampleReport].[SummaryResponses]([StartDate] ASC, [EndDate] ASC)
    INCLUDE([Brand], [Market], [Questionnaire])


