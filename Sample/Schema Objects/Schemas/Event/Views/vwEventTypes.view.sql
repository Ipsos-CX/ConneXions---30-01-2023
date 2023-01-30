CREATE VIEW [Event].[vwEventTypes]

AS

SELECT ET.EventTypeID, ET.EventType, EC.EventCategoryID, EC.EventCategory
FROM Event.EventTypes ET
INNER JOIN Event.EventTypeCategories ETC ON ETC.EventTypeID = ET.EventTypeID
INNER JOIN Event.EventCategories EC ON EC.EventCategoryID = ETC.EventCategoryID