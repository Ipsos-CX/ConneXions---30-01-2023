CREATE NONCLUSTERED INDEX [IX_Audit_ContactPreferencesBySurvey_OverridePreference]
    ON [Audit].[ContactPreferencesBySurvey]([OverridePreferences] ASC)
    INCLUDE([PartyID], [EventCategoryID], [UpdateDate]);
GO
