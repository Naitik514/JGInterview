USE [JGBS_Dev_New]
GO
/****** Object:  StoredProcedure [dbo].[GetFrozenTasks]    Script Date: 06/04/2017 10:39:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GetFrozenTasks] 
	-- Add the parameters for the stored procedure here
	@search varchar(100),
	@startdate varchar(50),
	@enddate varchar(50),
	@PageIndex INT , 
	@PageSize INT ,
	@userid int,
	@desigid int

AS
BEGIN

DECLARE @StartIndex INT  = 0
SET @StartIndex = (@PageIndex * @PageSize) + 1


if @search<>''
	begin
		;WITH 
		Tasklist AS
		(
				select  distinct(TaskId) ,[Description],[Status],convert(Date,DueDate ) as DueDate,
			Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,InstallId
			FROM
			(
			select  TaskId ,[Description],[Status],convert(Date,DueDate ) as DueDate,
				Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,
				case 
					when (ParentTaskId is null and  TaskLevel=1) then InstallId 
					when (tasklevel =1 and ParentTaskId>0) then 
						(select installid from tbltask where taskid=x.parenttaskid) +'-'+InstallId  
					when (tasklevel =2 and ParentTaskId>0) then
					 (select InstallId from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
					
					when (tasklevel =3 and ParentTaskId>0) then
					(select InstallId from tbltask where taskid in (
					(select parenttaskid from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))))
					+'-'+
					 (select InstallId from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
				end as 'InstallId' ,Row_number() OVER (  order by x.TaskId ) AS RowNo_Order
				from (
										select a.TaskId,a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
					 from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c,
					tblInstallUsers as t 
					where a.TaskId=b.TaskId and b.UserId=c.UserId 
					and b.TaskId=c.TaskId and c.UserId=t.Id 
					AND  ( 
					t.FristName LIKE '%'+@search+'%'  or 
					t.LastName LIKE '%'+@search+'%'  or 
					t.Email LIKE '%'+@search+'%' 
					)  and  tasklevel=1 and parenttaskid is not null
					and (AdminStatus = 1 OR TechLeadStatus = 1)
					
					--and (DateCreated >=@startdate  
					--and DateCreated <= @enddate) 

					union all

					SELECT a.TaskId,a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
					from dbo.tblTask as a,  tbltaskassignedusers as c,
					tbltaskapprovals as b,tblInstallUsers as t
					where   a.MainParentId=b.TaskId and b.UserId=t.Id  
					and b.UserId=c.UserId and b.TaskId=c.TaskId
					AND  (
					t.FristName LIKE '%'+ @search + '%'  or
					t.LastName LIKE '%'+ @search + '%'  or
					t.Email LIKE '%' + @search +'%'  
					) 
					and parenttaskid is not null
					and (AdminStatus = 1 OR TechLeadStatus = 1)
			) as x
			) as y
		)

		SELECT *,Row_number() OVER (  order by Tasklist.TaskId ) AS RowNo_Order
		INTO #temp
		FROM Tasklist


		SELECT * 
		FROM #temp 
		WHERE 
			RowNo_Order >= @StartIndex AND 
			(
				@PageSize = 0 OR 
				RowNo_Order < (@StartIndex + @PageSize)
			)
		ORDER BY RowNo_Order

		SELECT
		COUNT(*) AS TotalRecords
		FROM #temp
	end
else if @userid=0 and @desigid=0
	begin
		;WITH 
		Tasklist AS
		(
			select  distinct(TaskId) ,[Description],[Status],convert(Date,DueDate ) as DueDate,
			Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,InstallId
			FROM
			(
			select  TaskId ,[Description],[Status],convert(Date,DueDate ) as DueDate,
			Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,
			case 
				when (ParentTaskId is null and  TaskLevel=1) then InstallId 
				when (tasklevel =1 and ParentTaskId>0) then 
					(select installid from tbltask where taskid=x.parenttaskid) +'-'+InstallId  
				when (tasklevel =2 and ParentTaskId>0) then
				 (select InstallId from tbltask where taskid in (
				(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
				+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
					
				when (tasklevel =3 and ParentTaskId>0) then
				(select InstallId from tbltask where taskid in (
				(select parenttaskid from tbltask where taskid in (
				(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))))
				+'-'+
				 (select InstallId from tbltask where taskid in (
				(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
				+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
			end as 'InstallId',Row_number() OVER (  order by x.TaskId ) AS RowNo_Order
			from (

				select distinct( a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
					from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c
					where a.TaskId=b.TaskId 
					and b.TaskId=c.TaskId  
					and  tasklevel=1 and parenttaskid is not null
					and (AdminStatus = 1 OR TechLeadStatus = 1)
				 --and (DateCreated >=@startdate  
				 --and DateCreated <= @enddate) 

				union all

					SELECT distinct( a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
					from dbo.tblTask as a
					where 
					parenttaskid is not null
					and (AdminStatus = 1 OR TechLeadStatus = 1)
			) as x
			) as y
		)


		SELECT *,Row_number() OVER (  order by Tasklist.TaskId ) AS RowNo_Order
		INTO #temp1
		FROM Tasklist


		SELECT * 
		FROM #temp1 
		WHERE 
			RowNo_Order >= @StartIndex AND 
			(
				@PageSize = 0 OR 
				RowNo_Order < (@StartIndex + @PageSize)
			)
		ORDER BY RowNo_Order

		SELECT
		COUNT(*) AS TotalRecords
		FROM #temp1
	end

else if @userid>0  
	begin
		;WITH 
		Tasklist AS
		(
				select  distinct(TaskId) ,[Description],[Status],convert(Date,DueDate ) as DueDate,
			Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,InstallId
			FROM
			(
			select  TaskId ,[Description],[Status],convert(Date,DueDate ) as DueDate,
				Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,
				case 
					when (ParentTaskId is null and  TaskLevel=1) then InstallId 
					when (tasklevel =1 and ParentTaskId>0) then 
						(select installid from tbltask where taskid=x.parenttaskid) +'-'+InstallId  
					when (tasklevel =2 and ParentTaskId>0) then
					 (select InstallId from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
					
					when (tasklevel =3 and ParentTaskId>0) then
					(select InstallId from tbltask where taskid in (
					(select parenttaskid from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))))
					+'-'+
					 (select InstallId from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
				end as 'InstallId' ,Row_number() OVER (  order by x.TaskId ) AS RowNo_Order
				from (
					select distinct(a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
					from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c
					where a.TaskId=b.TaskId and b.TaskId=c.TaskId and c.UserId=@userid
					and  tasklevel=1 and parenttaskid is not null
					and (AdminStatus = 1 OR TechLeadStatus = 1)
					--and (DateCreated >=@startdate  
					--and DateCreated <= @enddate) 
					union all
				
					SELECT distinct(a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
					from dbo.tblTask as a,  tbltaskapprovals as c
					where   a.MainParentId=c.TaskId    and c.UserId=@userid
					and parenttaskid is not null
					and (AdminStatus = 1 OR TechLeadStatus = 1)

			) as x
			) as y
		)

		SELECT *,Row_number() OVER (  order by Tasklist.TaskId ) AS RowNo_Order
		INTO #temp2
		FROM Tasklist


		SELECT * 
		FROM #temp2 
		WHERE 
			RowNo_Order >= @StartIndex AND 
			(
				@PageSize = 0 OR 
				RowNo_Order < (@StartIndex + @PageSize)
			)
		ORDER BY RowNo_Order

		SELECT
		COUNT(*) AS TotalRecords
		FROM #temp2
	end

else if @userid=0 and @desigid>0
	begin
		;WITH 
		Tasklist AS
		(
				select  distinct(TaskId) ,[Description],[Status],convert(Date,DueDate ) as DueDate,
			Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,InstallId
			FROM
			(
			select  TaskId ,[Description],[Status],convert(Date,DueDate ) as DueDate,
				Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,
				case 
					when (ParentTaskId is null and  TaskLevel=1) then InstallId 
					when (tasklevel =1 and ParentTaskId>0) then 
						(select installid from tbltask where taskid=x.parenttaskid) +'-'+InstallId  
					when (tasklevel =2 and ParentTaskId>0) then
					 (select InstallId from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
					
					when (tasklevel =3 and ParentTaskId>0) then
					(select InstallId from tbltask where taskid in (
					(select parenttaskid from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))))
					+'-'+
					 (select InstallId from tbltask where taskid in (
					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
				end as 'InstallId' ,Row_number() OVER (  order by x.TaskId ) AS RowNo_Order
				from (
					--select a.* from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c,
					--tblTaskdesignations as d
					--where a.TaskId=b.TaskId and b.TaskId=c.TaskId and c.TaskId=d.TaskId
					--and (DateCreated >=@startdate  
					--and DateCreated <= @enddate) 

					select distinct(a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
					 from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c,
					 tblTaskdesignations as d
					where a.TaskId=b.TaskId 
					and b.TaskId=c.TaskId  and c.TaskId=d.TaskId and d.DesignationID=@desigid
					 and  tasklevel=1 and parenttaskid is not null
					and (AdminStatus = 1 OR TechLeadStatus = 1)

					 union all

					 	SELECT distinct(a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
					from dbo.tblTask as a,  tbltaskassignedusers as c,tblTaskdesignations as d,
					tbltaskapprovals as b 
					where   a.MainParentId=b.TaskId  and d.DesignationID=@desigid
					 and b.TaskId=c.TaskId and c.TaskId=d.TaskId
					and parenttaskid is not null
					and (AdminStatus = 1 OR TechLeadStatus = 1)

			) as x
			) as y
		)

		SELECT *,Row_number() OVER (  order by Tasklist.TaskId ) AS RowNo_Order
		INTO #temp3
		FROM Tasklist


		SELECT * 
		FROM #temp3
		WHERE 
			RowNo_Order >= @StartIndex AND 
			(
				@PageSize = 0 OR 
				RowNo_Order < (@StartIndex + @PageSize)
			)
		ORDER BY RowNo_Order

		SELECT
		COUNT(*) AS TotalRecords
		FROM #temp3
	end

--if @search<>''
--	begin
--		;WITH 
--		Tasklist AS
--		(
--				select  TaskId ,[Description],[Status],convert(Date,DueDate ) as DueDate,
--				Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,
--				case 
--					when (ParentTaskId is null and  TaskLevel=1) then InstallId 
--					when (tasklevel =1 and ParentTaskId>0) then 
--						(select installid from tbltask where taskid=x.parenttaskid) +'-'+InstallId  
--					when (tasklevel =2 and ParentTaskId>0) then
--					 (select InstallId from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
--					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
					
--					when (tasklevel =3 and ParentTaskId>0) then
--					(select InstallId from tbltask where taskid in (
--					(select parenttaskid from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))))
--					+'-'+
--					 (select InstallId from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
--					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
--				end as 'InstallId' ,Row_number() OVER (  order by x.TaskId ) AS RowNo_Order
--				from (
--					select a.TaskId,a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
--					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
--					 from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c,
--					tblInstallUsers as t 
--					where a.TaskId=b.TaskId and b.UserId=c.UserId 
--					and b.TaskId=c.TaskId and c.UserId=t.Id 
--					AND  ( 
--					t.FristName LIKE '%'+@search+'%'  or 
--					t.LastName LIKE '%'+@search+'%'  or 
--					t.Email LIKE '%'+@search+'%' 
--					)  and  tasklevel=1 and parenttaskid is not null
					
--					--and (DateCreated >=@startdate  
--					--and DateCreated <= @enddate) 

--					union all

--					SELECT a.TaskId,a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
--					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
--					from dbo.tblTask as a,  tbltaskassignedusers as c,
--					tbltaskapprovals as b,tblInstallUsers as t
--					where   a.MainParentId=b.TaskId and b.UserId=t.Id  
--					and b.UserId=c.UserId and b.TaskId=c.TaskId
--					AND  (
--					t.FristName LIKE '%'+ @search + '%'  or
--					t.LastName LIKE '%'+ @search + '%'  or
--					t.Email LIKE '%' + @search +'%'  
--					) 
--					and parenttaskid is not null
--			) as x
--		)

--		SELECT *
--		INTO #temp
--		FROM Tasklist
--		WHERE (AdminStatus = 1 OR TechLeadStatus = 1)


--		SELECT * 
--		FROM #temp 
--		WHERE 
--			RowNo_Order >= @StartIndex AND 
--			(
--				@PageSize = 0 OR 
--				RowNo_Order < (@StartIndex + @PageSize)
--			)
--		ORDER BY RowNo_Order

--		SELECT
--		COUNT(*) AS TotalRecords
--		FROM #temp
--	end
--else if @userid=0 and @desigid=0
--	begin
--		;WITH 
--		Tasklist AS
--		(
--			select  TaskId ,[Description],[Status],convert(Date,DueDate ) as DueDate,
--			Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,
--			case 
--				when (ParentTaskId is null and  TaskLevel=1) then InstallId 
--				when (tasklevel =1 and ParentTaskId>0) then 
--					(select installid from tbltask where taskid=x.parenttaskid) +'-'+InstallId  
--				when (tasklevel =2 and ParentTaskId>0) then
--				 (select InstallId from tbltask where taskid in (
--				(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
--				+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
					
--				when (tasklevel =3 and ParentTaskId>0) then
--				(select InstallId from tbltask where taskid in (
--				(select parenttaskid from tbltask where taskid in (
--				(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))))
--				+'-'+
--				 (select InstallId from tbltask where taskid in (
--				(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
--				+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
--			end as 'InstallId',Row_number() OVER (  order by x.TaskId ) AS RowNo_Order
--			from (

--				select distinct( a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
--					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
--					from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c
--					where a.TaskId=b.TaskId 
--					and b.TaskId=c.TaskId  
--					and  tasklevel=1 and parenttaskid is not null
--				 --and (DateCreated >=@startdate  
--				 --and DateCreated <= @enddate) 

--				union all

--					SELECT distinct( a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
--					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
--					from dbo.tblTask as a,  tbltaskassignedusers as c,
--					tbltaskapprovals as b 
--					where   a.MainParentId=b.TaskId  and
--					 b.TaskId=c.TaskId
--					and parenttaskid is not null


--			) as x
--		)


--		SELECT *
--		INTO #temp1
--		FROM Tasklist
--		WHERE (AdminStatus = 1 OR TechLeadStatus = 1)


--		SELECT * 
--		FROM #temp1 
--		WHERE 
--			RowNo_Order >= @StartIndex AND 
--			(
--				@PageSize = 0 OR 
--				RowNo_Order < (@StartIndex + @PageSize)
--			)
--		ORDER BY RowNo_Order

--		SELECT
--		COUNT(*) AS TotalRecords
--		FROM #temp1
--	end

--else if @userid>0  
--	begin
--		;WITH 
--		Tasklist AS
--		(
--				select  TaskId ,[Description],[Status],convert(Date,DueDate ) as DueDate,
--				Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,
--				case 
--					when (ParentTaskId is null and  TaskLevel=1) then InstallId 
--					when (tasklevel =1 and ParentTaskId>0) then 
--						(select installid from tbltask where taskid=x.parenttaskid) +'-'+InstallId  
--					when (tasklevel =2 and ParentTaskId>0) then
--					 (select InstallId from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
--					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
					
--					when (tasklevel =3 and ParentTaskId>0) then
--					(select InstallId from tbltask where taskid in (
--					(select parenttaskid from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))))
--					+'-'+
--					 (select InstallId from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
--					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
--				end as 'InstallId' ,Row_number() OVER (  order by x.TaskId ) AS RowNo_Order
--				from (
--					select distinct(a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
--					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
--					from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c
--					where a.TaskId=b.TaskId and b.TaskId=c.TaskId and c.UserId=@userid
--					and  tasklevel=1 and parenttaskid is not null
--					--and (DateCreated >=@startdate  
--					--and DateCreated <= @enddate) 
--					union all
				
--					SELECT distinct(a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
--					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
--					from dbo.tblTask as a,  tbltaskapprovals as c
--					where   a.MainParentId=c.TaskId    and c.UserId=@userid
--					and parenttaskid is not null

--			) as x
--		)

--		SELECT *
--		INTO #temp2
--		FROM Tasklist
--		WHERE (AdminStatus = 1 OR TechLeadStatus = 1)


--		SELECT * 
--		FROM #temp2 
--		WHERE 
--			RowNo_Order >= @StartIndex AND 
--			(
--				@PageSize = 0 OR 
--				RowNo_Order < (@StartIndex + @PageSize)
--			)
--		ORDER BY RowNo_Order

--		SELECT
--		COUNT(*) AS TotalRecords
--		FROM #temp2
--	end

--else if @userid=0 and @desigid>0
--	begin
--		;WITH 
--		Tasklist AS
--		(
--				select  TaskId ,[Description],[Status],convert(Date,DueDate ) as DueDate,
--				Title,[Hours],ParentTaskId,TaskLevel,InstallId as InstallId1,AdminStatus,TechLeadStatus,OtherUserStatus,
--				case 
--					when (ParentTaskId is null and  TaskLevel=1) then InstallId 
--					when (tasklevel =1 and ParentTaskId>0) then 
--						(select installid from tbltask where taskid=x.parenttaskid) +'-'+InstallId  
--					when (tasklevel =2 and ParentTaskId>0) then
--					 (select InstallId from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
--					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
					
--					when (tasklevel =3 and ParentTaskId>0) then
--					(select InstallId from tbltask where taskid in (
--					(select parenttaskid from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))))
--					+'-'+
--					 (select InstallId from tbltask where taskid in (
--					(select parentTaskId from tbltask where   taskid=x.parenttaskid) ))
--					+'-'+ (select InstallId from tbltask where   taskid=x.parenttaskid)	+ '-' +InstallId 
--				end as 'InstallId' ,Row_number() OVER (  order by x.TaskId ) AS RowNo_Order
--				from (
--					--select a.* from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c,
--					--tblTaskdesignations as d
--					--where a.TaskId=b.TaskId and b.TaskId=c.TaskId and c.TaskId=d.TaskId
--					--and (DateCreated >=@startdate  
--					--and DateCreated <= @enddate) 

--					select distinct(a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
--					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
--					 from tbltask as a,tbltaskapprovals as b,tbltaskassignedusers as c,
--					 tblTaskdesignations as d
--					where a.TaskId=b.TaskId 
--					and b.TaskId=c.TaskId  and c.TaskId=d.TaskId and d.DesignationID=@desigid
--					 and  tasklevel=1 and parenttaskid is not null

--					 union all

--					 	SELECT distinct(a.TaskId),a.[Description],a.[Status],convert(Date,a.DueDate ) as DueDate,
--					a.Title,a.[Hours],a.InstallId ,a.ParentTaskId,a.TaskLevel,a.AdminStatus,a.TechLeadStatus,a.OtherUserStatus
--					from dbo.tblTask as a,  tbltaskassignedusers as c,tblTaskdesignations as d,
--					tbltaskapprovals as b 
--					where   a.MainParentId=b.TaskId  and d.DesignationID=@desigid
--					 and b.TaskId=c.TaskId and c.TaskId=d.TaskId
--					and parenttaskid is not null

--			) as x
--		)

--		SELECT *
--		INTO #temp3
--		FROM Tasklist
--		WHERE (AdminStatus = 1 OR TechLeadStatus = 1)


--		SELECT * 
--		FROM #temp3
--		WHERE 
--			RowNo_Order >= @StartIndex AND 
--			(
--				@PageSize = 0 OR 
--				RowNo_Order < (@StartIndex + @PageSize)
--			)
--		ORDER BY RowNo_Order

--		SELECT
--		COUNT(*) AS TotalRecords
--		FROM #temp3
--	end
END
