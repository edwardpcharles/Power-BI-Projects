import csv
import random
from datetime import datetime, timedelta
from collections import defaultdict

# --- Customization Section ---
first_names = ["James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica", "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa", "Matthew", "Betty", "Anthony", "Margaret", "Mark", "Sandra"]
last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson"]

locations_doctors = [
    ("Downtown Clinic", "Dr. Sarah Johnson"),
    ("Downtown Clinic", "Dr. Michael Brown"),
    ("Downtown Clinic", "Dr. Emily White"),
    ("Downtown Clinic", "Dr. Daniel Moore"),
    ("Northside Medical", "Dr. Patricia Williams"),
    ("Northside Medical", "Dr. Richard Davis"),
    ("Northside Medical", "Dr. Christopher Lee"),
    ("Northside Medical", "Dr. Sophia Anderson"),
    ("Westfield Family Practice", "Dr. Jennifer Clark"),
    ("Westfield Family Practice", "Dr. Andrew Miller"),
    ("Westfield Family Practice", "Dr. Jessica Taylor"),
    ("Eastside Urgent Care", "Dr. Lisa Thompson"),
    ("Eastside Urgent Care", "Dr. Matthew Garcia"),
    ("Eastside Urgent Care", "Dr. David Martinez"),
    ("Southside Specialists", "Dr. Amanda Rodriguez"),
    ("Southside Specialists", "Dr. Robert Kim"),
    ("Southside Specialists", "Dr. Olivia Hernandez")
]

appointment_details = {
    "Check-up": {"duration_minutes": [20, 30], "note": "Routine wellness visit."},
    "Consultation": {"duration_minutes": [30, 45], "note": "New patient consultation."},
    "Follow-up": {"duration_minutes": [15, 20], "note": "Medication review and follow-up."},
    "Surgery": {"duration_minutes": [60, 120], "note": "Minor surgical procedure."},
    "Emergency": {"duration_minutes": [15, 45], "note": "Urgent care visit."}
}

def generate_random_time(start_hour, end_hour):
    hour = random.randint(start_hour, end_hour)
    minute = random.choice([0, 15, 30, 45])
    return timedelta(hours=hour, minutes=minute)

def generate_random_date(start, end):
    date = start + timedelta(days=random.randint(0, (end - start).days))
    while date.weekday() >= 5:  # Skip weekends
        date = start + timedelta(days=random.randint(0, (end - start).days))
    return date

def create_appointments(num_rows):
    appointments = []
    start_date = datetime(2023, 1, 1)
    end_date = datetime(2025, 8, 23)
    
    for _ in range(num_rows):
        location, doctor = random.choice(locations_doctors)
        patient_name = f"{random.choice(first_names)} {random.choice(last_names)}"
        appt_date = generate_random_date(start_date, end_date)
        start_time_delta = generate_random_time(8, 16)
        start_datetime = datetime.combine(appt_date, datetime.min.time()) + start_time_delta

        appt_type = random.choice(list(appointment_details.keys()))
        details = appointment_details[appt_type]
        duration = random.randint(*details["duration_minutes"])
        end_datetime = start_datetime + timedelta(minutes=duration)

        appointments.append({
            "OfficeLocation": location,
            "DoctorName": doctor,
            "PatientName": patient_name,
            "AppointmentDate": appt_date.strftime("%Y-%m-%d"),
            "StartDateTime": start_datetime,
            "EndDateTime": end_datetime,
            "AppointmentStart": start_datetime.strftime("%H:%M"),
            "AppointmentEnd": end_datetime.strftime("%H:%M"),
            "AppointmentType": appt_type,
            "Notes": details["note"]
        })

    return appointments

def assign_lanes(appointments):
    # Group appointments by location, doctor, and date
    grouped = defaultdict(list)
    for appt in appointments:
        key = (appt["OfficeLocation"], appt["DoctorName"], appt["AppointmentDate"])
        grouped[key].append(appt)

    # Assign lanes for each group
    for key, appts in grouped.items():
        # Sort by start time
        sorted_appts = sorted(appts, key=lambda x: x["StartDateTime"])
        lanes = []

        for appt in sorted_appts:
            assigned = False
            for lane_index, lane in enumerate(lanes):
                # Check if this lane is free (last end time < current start time)
                if lane[-1]["EndDateTime"] <= appt["StartDateTime"]:
                    lane.append(appt)
                    appt["Lane"] = lane_index
                    assigned = True
                    break

            if not assigned:
                # Start a new lane
                appt["Lane"] = len(lanes)
                lanes.append([appt])

    return appointments

if __name__ == "__main__":
    num_records_to_generate = 200000
    output_file_name = "medical_appointments_with_lanes.csv"

    print(f"Generating {num_records_to_generate} appointment records...")

    data = create_appointments(num_records_to_generate)
    data_with_lanes = assign_lanes(data)

    header = ["OfficeLocation", "DoctorName", "PatientName", "AppointmentDate", "AppointmentStart", "AppointmentEnd", "AppointmentType", "Notes", "Lane"]
    
    with open(output_file_name, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for appt in data_with_lanes:
            writer.writerow([
                appt["OfficeLocation"],
                appt["DoctorName"],
                appt["PatientName"],
                appt["AppointmentDate"],
                appt["AppointmentStart"],
                appt["AppointmentEnd"],
                appt["AppointmentType"],
                appt["Notes"],
                appt["Lane"]
            ])

    print(f"Successfully created '{output_file_name}' with {num_records_to_generate} rows.")
