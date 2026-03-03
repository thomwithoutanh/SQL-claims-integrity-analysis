-- Check data linkages between the patient and billing tables
SELECT *
FROM data-analytics-bootcamp-4.Hospital_management.billing as b
WHERE b.patient_id NOT IN (SELECT p.patient_id FROM data-analytics-bootcamp-4.Hospital_management.patients as p);


-- Check data linkages between the billing and treatment tables
SELECT *
FROM data-analytics-bootcamp-4.Hospital_management.billing as b
WHERE b.treatment_id NOT IN (SELECT t.treatment_id FROM data-analytics-bootcamp-4.Hospital_management.treatments as t);


-- Check for differences between appointment dates, treatment dates and billing dates
SELECT a.appointment_date, DATE_DIFF(a.appointment_date, t.treatment_date, day) AS days_after_appointment, t.treatment_date, b.bill_date, DATE_DIFF(t.treatment_date, b.bill_date, day) AS days
FROM data-analytics-bootcamp-4.Hospital_management.treatments as t
JOIN data-analytics-bootcamp-4.Hospital_management.billing as b
  ON t.treatment_id = b.treatment_id
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
  ON t.appointment_id = a.appointment_id
ORDER BY days_after_appointment DESC;

-- Show the number of distinct addresses listed in the patients table
SELECT DISTINCT address, COUNT(address) AS number_of_addresses
FROM data-analytics-bootcamp-4.Hospital_management.patients as P
GROUP BY address
ORDER BY COUNT(address) DESC;

-- Show number of patients and number of email addresses
SELECT COUNT(DISTINCT patient_id) AS number_of_patients, COUNT(DISTINCT email) AS number_of_email_addresses
FROM data-analytics-bootcamp-4.Hospital_management.patients as p;


-- Show patient name and ID for emails associated with michael.taylor@mail.com 
SELECT p.patient_id,
      CONCAT(p.first_name, ' ', p.last_name) AS full_name,
      email,
       COUNT(email) OVER (PARTITION BY email) as number_emails
FROM data-analytics-bootcamp-4.Hospital_management.patients as p
ORDER BY number_emails DESC
LIMIT 3;



-- Show patients who have attended appointments before their registration date
SELECT p.patient_id,
      CONCAT(p.first_name, ' ', p.last_name) AS full_name,
      COUNT(p.patient_id) AS appointments_before_registration
FROM data-analytics-bootcamp-4.Hospital_management.appointments as A
JOIN data-analytics-bootcamp-4.Hospital_management.patients as P
  ON a.patient_id = p.patient_id
WHERE (DATE_DIFF(p.registration_date, a.appointment_date, day)) > 14
GROUP BY p.patient_id, full_name
ORDER BY COUNT(p.patient_id) DESC;


-- Count common ‘female’ names assigned to the male gender and common ‘male’ names assigned to the female gender
SELECT COUNT(DISTINCT p.patient_id) AS names_for_checking
FROM data-analytics-bootcamp-4.Hospital_management.patients as P
WHERE (p.gender = 'M' AND p.first_name IN('Sarah','Laura','Linda')) OR (p.gender = 'F' AND p.first_name IN ('David','Michael','Robert'));

-- Show patients that attended the highest number of appointments and the amount billed for each of those appointments
WITH stats AS (
  SELECT  ROUND((SUM(DISTINCT b.amount))/COUNT(a.appointment_id),2) as AVG_COST_PER_APPOINTMENT
FROM data-analytics-bootcamp-4.Hospital_management.billing as b
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON b.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
    ON a.patient_id = p.patient_id
)
SELECT b.patient_id,
      CONCAT(p.first_name, ' ', p.last_name) AS full_name,
      ROUND(SUM(DISTINCT b.amount),2) AS total_billed,
      COUNT(DISTINCT a.appointment_id) AS number_appointments,
      ROUND(SUM(b.amount)/COUNT(a.appointment_id),2) AS cost_per_appointment,      ROUND(SUM(b.amount)/COUNT(a.appointment_id)-s.AVG_COST_PER_APPOINTMENT,2) AS difference_from_average_appointment_cost
FROM data-analytics-bootcamp-4.Hospital_management.billing as b
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON b.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
    ON a.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.treatments as t
  ON a.appointment_id = t.appointment_id
JOIN stats as s ON b.patient_id = p.patient_id
GROUP BY b.patient_id, full_name, s.AVG_COST_PER_APPOINTMENT
ORDER BY total_billed DESC;

-- Show the total billed by the identified high-risk patients
SELECT ROUND(SUM(b.amount),2) AS total_billed
FROM data-analytics-bootcamp-4.Hospital_management.billing as b
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON b.patient_id = p.patient_id
WHERE  p.patient_id IN ('P012', 'P049', 'P016', 'P036', 'P025', 'P005', 'P035');

-- Show amount billed for each type of reason for visit
SELECT
  a.reason_for_visit,
  COUNT(DISTINCT a.appointment_id) AS number_appointments,
  ROUND(SUM(b.amount),2) AS total_billed,
FROM data-analytics-bootcamp-4.Hospital_management.billing AS b
JOIN data-analytics-bootcamp-4.Hospital_management.patients AS p
  ON b.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.appointments AS a
  ON a.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.treatments AS t
  ON t.treatment_id = b.treatment_id
GROUP BY a.reason_for_visit
ORDER BY number_appointments DESC;


-- Show top five patients who have received 3 or more advanced protocol treatments
SELECT a.patient_id, 
CONCAT(p.first_name, ' ', p.last_name) AS full_name, t.description, 
COUNT(t.description) as number_of_treatments
FROM data-analytics-bootcamp-4.Hospital_management.treatments as t
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
    ON t.appointment_id = a.appointment_id
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON a.patient_id = p.patient_id
WHERE t.description = 'Advanced protocol'
GROUP BY a.patient_id, full_name, t.description
HAVING COUNT(t.description) > 2
ORDER BY COUNT(t.description) DESC
LIMIT 5;

-- Show level of treatment given to selected high-risk patients
SELECT p.patient_id, CONCAT(p.first_name, ' ', p.last_name) AS full_name,
    COUNT(t.description) AS number_treatments,
    SUM(CASE
        WHEN description = 'Advanced protocol' THEN 1
        ELSE 0
        END) AS number_advanced_protocol,
    SUM(CASE
        WHEN description = 'Standard procedure' THEN 1
        ELSE 0
        END) AS number_standard_procedure,
    SUM(CASE
        WHEN description = 'Basic screening' THEN 1
        ELSE 0
        END) AS number_basic_screening,
    ROUND(SUM(CASE
        WHEN description = 'Basic screening' THEN 1
        WHEN description = 'Standard procedure' THEN 1
        ELSE 0
        END)/COUNT(t.description)*100,1) AS percentage_basic_or_standard
FROM data-analytics-bootcamp-4.Hospital_management.treatments as t
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
    ON t.appointment_id = a.appointment_id
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON a.patient_id = p.patient_id
WHERE p.patient_id IN ('P012', 'P049', 'P016', 'P036', 'P025', 'P005', 'P035')
GROUP BY p.patient_id, full_name
ORDER BY number_advanced_protocol;

-- Show type of treatment given to high-risk patients
SELECT p.patient_id, CONCAT(p.first_name, ' ', p.last_name) AS full_name,
    COUNT(t.description) AS number_treatments,
    SUM(CASE
        WHEN t.treatment_type = 'Physiotherapy' THEN 1
        ELSE 0
        END) AS number_physiotherapy,
    SUM(CASE
        WHEN t.treatment_type = 'X-Ray' THEN 1
        ELSE 0
        END) AS number_Xray,
    SUM(CASE
        WHEN t.treatment_type = 'ECG' THEN 1
        ELSE 0
        END) AS number_ECG,
    SUM(CASE
        WHEN t.treatment_type = 'Chemotherapy' THEN 1
        ELSE 0
        END) AS number_Chemotherapy,
    SUM(CASE
        WHEN t.treatment_type = 'MRI' THEN 1
        ELSE 0
        END) AS number_MRI
FROM data-analytics-bootcamp-4.Hospital_management.treatments as t
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
    ON t.appointment_id = a.appointment_id
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON a.patient_id = p.patient_id
WHERE p.patient_id IN ('P012', 'P049', 'P016', 'P036', 'P025', 'P005', 'P035')
GROUP BY p.patient_id, full_name
ORDER BY number_treatments DESC;

-- Show specialization of the doctors that saw the highest numbers of selected high-risk patients
SELECT d.specialization,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    ROUND(SUM(b.amount),2) AS total_billed
FROM data-analytics-bootcamp-4.Hospital_management.doctors as d
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
    ON d.doctor_id = a.doctor_id
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON a.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.billing as b
    ON b.patient_id = p.patient_id
WHERE a.patient_id IN ('P012', 'P049', 'P016', 'P036', 'P025', 'P005', 'P035')
GROUP BY d.specialization
ORDER BY total_appointments DESC;

-- Calculate age of high-risk patients
SELECT patient_id,
        date_of_birth,
        CONCAT(p.first_name, ' ', p.last_name) AS full_name,
        FLOOR(DATE_DIFF('2026-02-10',date_of_birth, DAY)/365) AS age
FROM data-analytics-bootcamp-4.Hospital_management.patients as P
WHERE patient_id IN ('P012', 'P049', 'P016', 'P036', 'P025', 'P005', 'P035')
ORDER BY age;

-- Show failed and pending billings linked to high-risk patients
SELECT ROUND(SUM(b.amount),2) AS total_failed_pending_billings
FROM data-analytics-bootcamp-4.Hospital_management.billing as B
JOIN data-analytics-bootcamp-4.Hospital_management.patients as P
    ON b.patient_id = p.patient_id
WHERE b.payment_status = 'Failed' AND p.patient_id IN ('P012', 'P049', 'P016', 'P036', 'P025', 'P005', 'P035');


SELECT ROUND(SUM(b.amount),2) AS total_pending_billings
FROM data-analytics-bootcamp-4.Hospital_management.billing as B
JOIN data-analytics-bootcamp-4.Hospital_management.patients as P
    ON b.patient_id = p.patient_id
WHERE b.payment_status IN ('Pending', ‘Failed’) AND p.patient_id IN ('P012', 'P049', 'P016', 'P036', 'P005', 'P035');



-- Show highest failed payments by high-risk patients
SELECT b.patient_id, 
	CONCAT(p.first_name, ' ', p.last_name) AS full_name, 
	ROUND(SUM(b.amount),2) AS total_failed_billings
FROM data-analytics-bootcamp-4.Hospital_management.billing as B
JOIN data-analytics-bootcamp-4.Hospital_management.patients as P
    ON b.patient_id = p.patient_id
WHERE b.payment_status = 'Failed' AND p.patient_id IN ('P012', 'P049', 'P016', 'P036', 'P005', 'P035')
GROUP BY b.patient_id, full_name
GROUP total_failed_billings > 7000
ORDER BY total_failed_billings DESC;

-- Show insurance payments that are unusually high and are either failed or pending
WITH stats AS (
    SELECT
        AVG(amount) AS mean,
        STDDEV(amount) AS stddev
    FROM data-analytics-bootcamp-4.Hospital_management.billing AS b
)
SELECT bill_id, patient_id, amount, payment_status
FROM data-analytics-bootcamp-4.Hospital_management.billing, stats
WHERE ABS(amount - mean) > 1.5 * STDDEV AND payment_status IN ('Failed','Pending') AND payment_method = 'Insurance'
ORDER BY amount DESC;


-- Categorise insurance providers by number of appointments and total amount billed
SELECT
  p.insurance_provider,
  COUNT(DISTINCT a.appointment_id) AS number_appointments,
  ROUND(SUM(b.amount),2) AS total_billed,
FROM data-analytics-bootcamp-4.Hospital_management.billing AS b
JOIN data-analytics-bootcamp-4.Hospital_management.patients AS p
  ON b.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.appointments AS a
  ON a.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.treatments AS t
  ON t.treatment_id = b.treatment_id
GROUP BY p.insurance_provider
ORDER BY total_billed DESC;

-- Show doctors that saw the selected high-risk patients most frequently
SELECT d.doctor_id, CONCAT(d.first_name, ' ', d.last_name) AS full_name, COUNT(a.appointment_id) AS total_appointments
FROM data-analytics-bootcamp-4.Hospital_management.doctors as d
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
    ON d.doctor_id = a.doctor_id
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON a.patient_id = p.patient_id
WHERE p.patient_id IN ('P012', 'P049', 'P016', 'P036', 'P025', 'P005', 'P035')
GROUP BY d.doctor_id, full_name
ORDER BY total_appointments DESC
LIMIT 5;


-- Identify doctors who billed most to MedCare Plus
SELECT d.doctor_id, 
CONCAT(d.first_name,' ',d.last_name) as full_name, ROUND(SUM(b.amount),2) as total_billed_per_doctor
FROM data-analytics-bootcamp-4.Hospital_management.doctors as d
JOIN data-analytics-bootcamp-4.Hospital_management.appointments as a
    ON d.doctor_id = a.doctor_id
JOIN data-analytics-bootcamp-4.Hospital_management.patients as p
    ON a.patient_id = p.patient_id
JOIN data-analytics-bootcamp-4.Hospital_management.billing as b
    ON b.patient_id = p.patient_id
WHERE p.insurance_provider = 'MedCare Plus'
GROUP BY d.doctor_id, full_name
ORDER BY total_billed_per_doctor DESC;

