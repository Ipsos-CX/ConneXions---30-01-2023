CREATE TABLE [Event].[EventTypes] (
    [EventTypeID]   dbo.EventTypeID       IDENTITY (1, 1) NOT NULL,
    [EventType] NVARCHAR (200) NOT NULL,
    [RelatedOutletFunctionID]  INT NULL
);

