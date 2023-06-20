CREATE OR REPLACE PROCEDURE inci_cre_sp (
  p_cust IN NUMBER,
  p_issue_typ IN VARCHAR2,
  p_issue_desc IN VARCHAR2,
  p_status OUT VARCHAR2
)
AS
  v_ref_id citi_inc_mgmt_tb.ref_id%TYPE;
  v_cust_id CITI_CUST_TB.CUST_ID%TYPE;
  v_mobile citi_cust_tb.mobile%TYPE;
BEGIN 
  -- Generate reference ID
  SELECT  TO_CHAR(SYSDATE, 'DDMMYYYY') || LPAD(inc_seq.nextval, 5, '0') 
  INTO v_ref_id 
  FROM dual;
  
  -- Fetch customer details
  SELECT cust_id, mobile INTO v_cust_id, v_mobile 
  FROM citi_cust_tb
  WHERE cust_id = p_cust;
  
  -- Validate issue type
  IF p_issue_typ NOT IN ('H', 'S') THEN
    RAISE_APPLICATION_ERROR(-20009, 'Invalid issue type');
  END IF;
  
  -- Validate issue description
  IF p_issue_desc IS NULL THEN 
    RAISE_APPLICATION_ERROR (-20010, 'Issue description must have a value');
  END IF;
  
  -- Insert incident record
  INSERT INTO citi_inc_mgmt_tb (ref_id, cust_id, mobile, issue_typ, issue_desc, status)
  VALUES (v_ref_id, p_cust, v_mobile, p_issue_typ, p_issue_desc, 'PFA');
  
  IF SQL%ROWCOUNT > 0 THEN
    p_status := 'success';
  ELSE
    p_status := 'error';
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20011, 'Customer ID does not exist');
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20012, 'An error occurred');
END;
/




DECLARE
  v_issue_typ VARCHAR2(1) := 'H';
  v_issue_desc VARCHAR2(100) := 'Issue description';
  v_status VARCHAR2(10);
BEGIN
    INCI_CRE_SP(1001,'H','Issue d',V_STATUS);  
    
    DBMS_OUTPUT.PUT_LINE(V_STATUS);
    
IF v_status = 'success' THEN
   DBMS_OUTPUT.PUT_LINE('Incident created successfully.');
ELSE
   DBMS_OUTPUT.PUT_LINE('Error creating incident.');
END IF;
END;
/

--2ND PROCEDURE IS FOR INCIDENT UPDATE 

create or replace procedure incident_update_sp(
  p_status varchar2  
  ,p_rej  varchar2
  ,p_ref_id number) 
AS
    
begin

if p_status not in ('A','R') 
then 
    raise_application_error(-20234,'status neither approved nor rejected ');
end if;

if p_status='A' and p_rej is not NULL
then 
    raise_application_error(-20204,'status  approved but rejectiondesc has data ');

elsif p_status='R' and p_rej is null 
then 
    raise_application_error(-20255,'status rejected  but rejectiondesc has  no data ');

elsif p_status='A' THEN

 update citi_inc_mgmt_tb set apr_by=user
                            , APT_DTTM=systimestamp;
else
update citi_inc_mgmt_tb set rej_by=user
                            , rej_dttm=systimestamp
                where ref_id=p_ref_id;

END IF;
dbms_output.put_line('updated rejection part');
end incident_update_sp;
/

--CALLING 2ND PROCEDURE

exec incident_update_sp('A','',1906202300250);



--3RD PROCEDURE IS FOR REOPEN THE INCIDENT 

create or replace procedure reopen_incident_sp(p_status varchar2)
AS

BEGIN
    if p_status='R'
    then 
    insert into citi_inc_mgmt_tb (info_cng_num) values(count(info_cng_num)+1);
    end if;
end reopen_incident_sp;
/



CREATE OR REPLACE PROCEDURE REOPEN_INCIDENT_SP(P_REF_ID varchar2
                                               ,p_status varchar2)
AS
v_count number;
BEGIN
    if p_status='R'
    THEN
    SELECT COUNT(*) INTO V_COUNT from citi_inc_mgmt_tb
    WHERE REF_ID=P_REF_ID;
    insert into citi_inc_mgmt_tb (info_cng_num) values(v_count+1);
    end if;
END REOPEN_INCIDENT_SP;
/

exec REOPEN_INCIDENT_SP(1906202300250,'R');



--1ST FUNCTION IS FOR GETTING STATUS OF INCIDENT.

create or replace function  incident_status_fn(p_ref in varchar2)
return varchar2
AS
v_status varchar2(300);
BEGIN
    select case status
	       when 'PFA' then 'Pending For Approval'
		   when 'A'   then 'Approved'
		   when 'R'   then 'Rejected'
		   end case  into v_status 
	from  citi_inc_mgmt_tb  where ref_id=p_ref;

return 	v_status;
end incident_status_fn;
/



select  incident_status_fn(1906202300250) from dual;







