USE [BankKrd]
GO
/****** Объект:  StoredProcedure [bis].[sp_exec_pcode]    Дата сценария: 12/06/2013 12:52:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER proc [bis].[sp_exec_pcode]
   @pcode nvarchar(250)
   , @args nvarchar(4000)
   , @quote_args bit = 0
   , @delim char(1) = ';'
   , @use_testsrv bit = 0
   , @srv_addr varchar(50) = null
   , @taskid varchar(50) = null
   , @spid smallint = null
   , @output bit = 0
with
--   encryption, 
   execute as owner
as
begin

	set nocount on;
	
   declare 
      @error int
      , @server_addr varchar(50)
      , @params dbo.t_message
      , @output_line dbo.t_message
      , @CmdLine nvarchar(4000)
      , @old_delim nvarchar(10)
      , @new_delim nvarchar(10)
      --
      , @username sysname
      , @branch_id varchar(10)
      ;
   
   execute as caller; -- get caller context
   
   select
      @spid = isnull(@spid, @@spid)
      , @username = system_user
      , @branch_id = dbo.fn_FilialCode()+dbo.fn_SubdivisionCode()
      
--      , @branch_id = left(replace(ltrim(rtrim(dbo.CurUsrRight())), '%', '03') + '00', 4)
   
   revert; -- return to owner context
   
   set @output_line = '';
   
   -- основной сервер
--   set @server_addr = '192.168.1.201 -S bq41d2';
   
   -- если выполняется на тестовой БД
--   if (db_name() = 'Developer' collate Cyrillic_General_CI_AS)
--   begin
--      set @use_testsrv = 1;
--   end;
   
   -- дополнительный
--   if (@use_testsrv = 1)
--      set @server_addr = '192.168.1.240 -S bq41d2';
   
   -- другой указанный
--   if (@srv_addr is not null)
--      set @server_addr = @srv_addr;
   
	begin try
      if (@taskid is not null) 
         insert into dbo.TaskInUse values (@taskid)
      
      exec master.sys.xp_fileexist @pcode, @error out;
      if (@error = 0) -- not exists
      begin
         set @params = dbo.format('Файл с П-кодом "{0}" не существует', @pcode);
         raiserror(@params, 16, 1);
      end;
      
	   if (@quote_args = 1)
	   begin
	      
	      
	      set @args = '';
	      select
	         @args = @args + quotename(item, '"') + ' '
	      from 
	         dbo.split(@args, @delim, 0);
	      ;
	      
--          -- устанавливаем новый разделитель
--          set @new_delim = ' ';
--          exec dbo.sp_set_concat_delim @new_delim, @old_delim out;
--          
-- 	      select
-- 	         @args = dbo.concat(quotename(item, '"')) 
-- 	      from 
-- 	         dbo.split(@args, @delim, 0);
-- 	      ;
-- 
--          -- восстанавливаем разделитель
--          exec dbo.sp_set_concat_delim @old_delim;
	      
	   end;
	   
--      set @CmdLine = dbo.format3('@echo {0} | c:\openedge\bin\prowin32.exe -b -db bisquit -dt PROGRESS -ld bisquit -N TCP -H {1} -p {2}'
      set @CmdLine = dbo.format3('@echo {0} | c:\openedge\bin\prowin32.exe -b -db bisquit -dt PROGRESS -ld bisquit -N TCP -p {2}'
         , dbo.format5('"{0}" "{1}" "{2}" "{3}" {4}'
            , @spid           -- user's spid
            , @username       -- user's login
            , @branch_id      -- user's branch
            , @@servername    -- current server name
            , dbo.format3('"{0}" {1}'
               , db_name()    -- current dbname
               , @args        -- агрументы для конкретного p-кода
               , null
            )
	      )
         , @server_addr
         , @pcode
      );
      if (@output = 1)
         print @CmdLine;
      
      declare
         @output_tbl table (row_num int identity, row nvarchar(255));
      
      --print dbo.[format]('{0:hh:mm:ss}', getdate());
      insert into @output_tbl(row)
         exec @error = master.dbo.xp_cmdshell @CmdLine;
      --print dbo.[format]('{0:hh:mm:ss}', getdate());
      
      -- проверяем на наличие ошибок
      set @error = case when @@error != 0 then @@error else @error end;

      -- устанавливаем новый разделитель
      set @new_delim = char(13);
      
      set @output_line = '';
      
      ;with c
      as
      (
         select
            t.row_num
            , LTRIM(RTRIM(t.row)) row
            , len(t.row) l
         from
            @output_tbl t
         where
            t.row_num = 1
         
         union all
         
         select
            t.row_num
            , LTRIM(RTRIM(t.row)) row
            , len(t.row)+c.l+1
         from
            @output_tbl t
            inner join c on c.row_num+1 = t.row_num
         where
            len(t.row)+c.l+1 < 4000
      )
      select 
         @output_line = @output_line + row + @new_delim
      from c 
      where 
         nullif(row, '') is not null
      option (maxrecursion 32767);
--       select 
--          @output_line = dbo.concat(row) 
--       from c 
--       where 
--          nullif(row, '') is not null
--       option (maxrecursion 32767);
      --print dbo.[format]('{0:hh:mm:ss}', getdate());

      -- восстанавливаем разделитель
--      exec dbo.sp_set_concat_delim @old_delim;
      
      -- если prowin не вернул ошибки
      if (@error = 0)
      begin
         -- проверяем наличие фразы "error code:" в выводе программы
         if (patindex('%error code:%', @output_line) > 0)
            set @error = 1; -- script error
      end;
      
      if (@error != 0)
         raiserror('Ошибка выполнения запроса из БИС''а (Код ошибки: %d)', 16, 1, @error);
      
      if (@output = 1)
         print @output_line

      if (@taskid is not null) 
         delete from dbo.TaskInUse where taskid = @taskid
	end try
	begin catch
      -- по кэтчу предыдущая инструкция не выполниться
      if (@taskid is not null) 
         delete from dbo.TaskInUse where taskid = @taskid

      if (nullif(ltrim(@CmdLine), '') is null)
         set @params = null;
      else
         set @params = dbo.format3('exec master.dbo.xp_cmdshell ''{0}''{1}{2}', @CmdLine, char(13), substring(@output_line, 1, 3000));
      
--      exec dbo.sp_log_rethrow 
--         @params = @params;
		SET @params=error_message()+char(13)+isnull(@params,'')
		raiserror(@params,16,1)
      
	end catch;
end;
----------------------------------------------------------------------------------------------------------------------------------------------------------
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Holdings]') AND type in (N'U'))
DROP TABLE [dbo].[Holdings]
