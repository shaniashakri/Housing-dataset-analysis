-- Displaying all data before we deep dive

SELECT *
FROM ProjectPortfolio3.dbo.NashvilleHousing

-- Query 1: Retrieve necessary data from the NashvilleHousing table
SELECT ParcelID, SaleDate, SalePrice, PropertyAddress, OwnerAddress, SoldAsVacant
FROM ProjectPortfolio03.dbo.NashvilleHousing;

-- Query 2: Standardizing the date format
-- Action: Add a new column for standardized sale dates and update existing sale dates
ALTER TABLE ProjectPortfolio03.dbo.NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE ProjectPortfolio03.dbo.NashvilleHousing
SET SaleDate = CONVERT(DATE, SaleDate),
    SaleDateConverted = SaleDate;

-- Query 3: Populating the missing Property Address values
-- Action: Fill in missing PropertyAddress values using a corresponding non-null value
UPDATE ProjectPortfolio03.dbo.NashvilleHousing
SET PropertyAddress = (
    SELECT TOP 1 PropertyAddress
    FROM ProjectPortfolio03.dbo.NashvilleHousing b
    WHERE b.ParcelID = NashvilleHousing.ParcelID AND b.PropertyAddress IS NOT NULL
);

-- Query 4: Split address into individual columns (Address, City)
-- Action: Split PropertyAddress into separate Address and City columns
ALTER TABLE ProjectPortfolio03.dbo.NashvilleHousing
ADD SplitPropertyAddress NVARCHAR(255),
    City NVARCHAR(255);

UPDATE ProjectPortfolio03.dbo.NashvilleHousing
SET SplitPropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Query 5: Split Owner Address into separate columns (Address, City, State)
-- Action: Split OwnerAddress into Address, City, and State columns
ALTER TABLE ProjectPortfolio03.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(255);

UPDATE ProjectPortfolio03.dbo.NashvilleHousing
SET OwnerSplitAddress = LEFT(OwnerAddress, CHARINDEX(',', OwnerAddress) - 1),
    OwnerSplitCity = SUBSTRING(OwnerAddress, CHARINDEX(',', OwnerAddress) + 1, CHARINDEX(',', OwnerAddress, CHARINDEX(',', OwnerAddress) + 1) - CHARINDEX(',', OwnerAddress) - 1),
    OwnerSplitState = RIGHT(OwnerAddress, CHARINDEX(' ', REVERSE(OwnerAddress)) - 1);


-- Query 6: Change Y and N to Yes and No in "Sold as vacant" column
-- Action: Update 'SoldAsVacant' column to replace Y and N with Yes and No respectively
UPDATE ProjectPortfolio03.dbo.NashvilleHousing
SET SoldAsVacant = CASE 
                        WHEN SoldAsVacant = 'Y' THEN 'Yes'
                        WHEN SoldAsVacant = 'N' THEN 'No'
                        ELSE SoldAsVacant
                    END;

-- Query 7: Remove duplicate records
-- Action: Identify and remove duplicate records based on specified criteria
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertyAddress,
                            SalePrice,
                            SaleDate,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM ProjectPortfolio03.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress


-- Query 8: Delete Unused Columns
-- Action: Remove specified columns which are no longer needed
ALTER TABLE ProjectPortfolio03.dbo.NashvilleHousing
DROP COLUMN OwnerAddress,
             TaxDistrict,
             PropertyAddress,
             SaleDate;


-- Query 9: Calculate Average Sale Price by Land Use:
SELECT LandUse, AVG(SalePrice) AS AvgSalePrice
FROM ProjectPortfolio03.dbo.NashvilleHousing
GROUP BY LandUse;


--Query 10: Identify Properties Sold Above/Below Market Value:
SELECT *,
       CASE
           WHEN SalePrice > AvgSalePrice THEN 'Above Market Value'
           WHEN SalePrice < AvgSalePrice THEN 'Below Market Value'
           ELSE 'Equal to Market Value'
       END AS MarketValueStatus
FROM ProjectPortfolio03.dbo.NashvilleHousing
JOIN (
    SELECT LandUse, AVG(SalePrice) AS AvgSalePrice
    FROM ProjectPortfolio03.dbo.NashvilleHousing
    GROUP BY LandUse
) AS AvgPrices ON NashvilleHousing.LandUse = AvgPrices.LandUse;


--Query 11: Calculate Sale Price Appreciation Rate:
SELECT *,
       ((SalePrice - PreviousSalePrice) / PreviousSalePrice) * 100 AS AppreciationRate
FROM (
    SELECT *,
           LAG(SalePrice) OVER (PARTITION BY ParcelID ORDER BY UniqueID) AS PreviousSalePrice
    FROM ProjectPortfolio03.dbo.NashvilleHousing
) AS PrevPrices;


--Query 12:
SELECT 
    ParcelID,
    SalePrice,
	LandUse,
    CASE 
        WHEN SalePrice > 100000 THEN 'Expensive'
        ELSE 'Affordable'
    END AS PriceCategory
FROM ProjectPortfolio03.dbo.NashvilleHousing
ORDER BY PriceCategory DESC;






