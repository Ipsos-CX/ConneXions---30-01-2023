CREATE NONCLUSTERED INDEX [IX_Audit_PartyContactMechanismPurposes_AuditItemID_ContactMechanismID]
    ON [Audit].[PartyContactMechanismPurposes]([auditItemID] ASC,[ContactMechanismID] ASC)
    INCLUDE(ContactMechanismPurposeTypeID) 

