<?php
require('fpdf/fpdf.php');
include '../db.php';

class PDF extends FPDF
{
    function Header()
    {
        $this->SetFont('Arial', 'B', 16);
        $this->Cell(0, 10, 'Inventory Report', 0, 1, 'C');
        $this->Ln(5);

        $this->SetFont('Arial', 'B', 12);
        $this->Cell(60, 10, 'Material Name', 1, 0, 'C');
        $this->Cell(25, 10, 'Quantity', 1, 0, 'C');
        $this->Cell(25, 10, 'Type', 1, 0, 'C');
        $this->Cell(25, 10, 'Unit', 1, 0, 'C');
        $this->Cell(50, 10, 'Last Updated', 1, 1, 'C');
    }

    function Footer()
    {
        $this->SetY(-15);
        $this->SetFont('Arial', 'I', 8);
        $this->Cell(0, 10, 'Generated on ' . date('Y-m-d H:i:s'), 0, 0, 'C');
    }
}

$pdf = new PDF();
$pdf->AddPage();
$pdf->SetFont('Arial', '', 12);

$query = "SELECT name, quantity, type, unit, created_at FROM raw_materials WHERE status = 'visible'";
$result = $conn->query($query);

if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $pdf->Cell(60, 10, $row['name'], 1);
        $pdf->Cell(25, 10, $row['quantity'], 1, 0, 'C');
        $pdf->Cell(25, 10, ucfirst($row['type']), 1, 0, 'C');
        $pdf->Cell(25, 10, $row['unit'], 1, 0, 'C');
        $pdf->Cell(50, 10, $row['created_at'], 1, 1, 'C');
    }
} else {
    $pdf->Cell(0, 10, 'No materials found', 1, 1, 'C');
}

$pdf->Output('I', 'inventory_report.pdf');
?>
