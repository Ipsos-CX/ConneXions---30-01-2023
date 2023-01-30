CREATE NONCLUSTERED INDEX [IX_Requirements_Requirement]
    ON [Requirement].[Requirements]([Requirement] ASC)
    INCLUDE([RequirementTypeID])

