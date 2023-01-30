CREATE TABLE [Audit].[EventDateTooYoung]
(
    [EventID] [dbo].[EventID] NOT NULL, 
    [SelectionCreationDate] DATETIME2(7) NOT NULL,
    CONSTRAINT [PK_EventDateTooYoung] PRIMARY KEY ([EventID])
)
