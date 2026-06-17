# SRJPEdata 1.0.1                                                                                                                                                                    
                                                                                                                                                                                
Updates included in this patch:                                                                                                                                                      

The patch updates the criteria for "years to exclude" to remove years with less than 3 weeks with catch data which results in the following changes.

- Updates `years_to_include_rst_data`: adds Feather River (Herringer Riffle) 2026 and removes Mill Creek 2025                                                                      
- Updates `years_to_exclude_rst_data`: adds Mill Creek 2025 (21 weeks sampled, 1 week with catch data) and updates Mill Creek 2026 number of weeks sampled (16 → 17); removes Feather River (Herringer Riffle) 2026 as this year meets the criteria
- Updates `years_to_include_adult`: corrects Yuba River 2023 upstream passage count (0 → 348) and adds Yuba River 2024 upstream passage count (668) 

# SRJPEdata 1.0.0

This release contains:
- RST (including mark recapture trials) data through the 2025/2026 monitoring season (2025/2026 is still considered preliminary). 
- Adult estimates through 2025 (aligns with 2025/2026 juvenile data), except for Yuba River which has data through 2024
- Updated flow and water temperature data through May 2026

This dataset will be used to develop a manuscript for the BTSPAS-X model.

Patches are planned for May-June 2026 that involve improvements to water temperature data processing and package documentation. The 2025/2026 RST data is expected to be finalized by July 2026 and released as a minor update to this version.

# SRJPEdata 0.0.2

Updates included in this patch:
- Adds temperature regression vignette
- Fixes some issues with environmental data prep

# SRJPEdata 0.0.1

Beta release of Spring Run Juvenile Production Estimate Datasets. The data produced by this package is intended to be used with the [SRJPEmodel package](https://github.com/SRJPE/SRJPEmodel). 
