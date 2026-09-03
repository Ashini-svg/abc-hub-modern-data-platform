from pathlib import Path
import csv


# -------------------------------------------------------------------
# ABC Hub source-data preparation
# -------------------------------------------------------------------
# Purpose:
#   Create ingestion-ready copies of the supplied CSV files without
#   modifying the original source package.
#
# This script only normalizes values that PostgreSQL expects to be
# integers but which are represented in the CSV as values such as
# "4.0".
# -------------------------------------------------------------------

SOURCE_DIR = Path(
    r"C:\Users\Ashini\Downloads\New folder\dw-fundamentals-bootcamp"
    r"\Z2D DWDF Mini Project 01\ABC Hub Data Package\packages\data"
)

OUTPUT_DIR = Path(
    r"C:\Users\Ashini\Downloads\New folder\dw-fundamentals-bootcamp"
    r"\Z2D DWDF Mini Project 01\ABC Hub Data Package\packages\abc-hub-data-engineering\data\prepared"
)


# Columns that must be integers in the PostgreSQL operational schema.
INTEGER_COLUMNS = {
    "content.csv": {"duration_minutes"},
    "streaming_session.csv": {"watch_duration"},
    "payment.csv": {"subscription_id", "rental_id"},
}


def normalize_integer(value: str) -> str:
    """Convert values such as '4.0' to '4'.

    Empty values are preserved because nullable fields must remain empty.
    """
    if value is None or value == "":
        return value

    try:
        number = float(value)

        if number.is_integer():
            return str(int(number))

    except ValueError:
        pass

    return value


def prepare_csv(filename: str, integer_columns: set[str]) -> None:
    source_file = SOURCE_DIR / filename
    output_file = OUTPUT_DIR / filename

    with source_file.open("r", newline="", encoding="utf-8-sig") as infile:
        reader = csv.DictReader(infile)

        if reader.fieldnames is None:
            raise ValueError(f"No header found in {source_file}")

        output_file.parent.mkdir(parents=True, exist_ok=True)

        with output_file.open(
            "w",
            newline="",
            encoding="utf-8"
        ) as outfile:

            writer = csv.DictWriter(
                outfile,
                fieldnames=reader.fieldnames
            )

            writer.writeheader()

            for row in reader:
                for column in integer_columns:
                    if column in row:
                        row[column] = normalize_integer(row[column])

                writer.writerow(row)

    print(f"Prepared: {filename}")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Copy every CSV unchanged unless it requires integer normalization.
    for source_file in sorted(SOURCE_DIR.glob("*.csv")):
        filename = source_file.name
        output_file = OUTPUT_DIR / filename

        integer_columns = INTEGER_COLUMNS.get(filename, set())

        with source_file.open("r", newline="", encoding="utf-8-sig") as infile:
            reader = csv.DictReader(infile)

            if reader.fieldnames is None:
                raise ValueError(f"No header found in {source_file}")

            with output_file.open(
                "w",
                newline="",
                encoding="utf-8"
            ) as outfile:

                writer = csv.DictWriter(
                    outfile,
                    fieldnames=reader.fieldnames
                )

                writer.writeheader()

                for row in reader:
                    for column in integer_columns:
                        if column in row:
                            row[column] = normalize_integer(row[column])

                    writer.writerow(row)

        print(f"Prepared: {filename}")

    print("\nSource-data preparation completed successfully.")


if __name__ == "__main__":
    main()