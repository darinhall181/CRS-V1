/**
 * Main wrapper interface for Camera Metadata.
 * This aggregates specific sub-categories of data.
 */
export interface CameraMetadata {
    product_info: ProductInfo;
    imaging_specs: ImagingSpecs;
    performance: PerformanceSpecs;
    hardware_features: HardwareFeatures;
  }
  
  /**
   * Basic commercial and identification details.
   */
  export interface ProductInfo {
    name: string;
    sku: string;
    price: number;
    currency: string;
    type: string; // e.g., "Mirrorless", "DSLR"
  }
  
  /**
   * Core specifications regarding the image capture pipeline.
   */
  export interface ImagingSpecs {
    sensor_resolution: string; // e.g., "24.2 megapixels"
    sensor_type: string;       // e.g., "Stacked CMOS"
    processor: string;
    lens_mount: string;
    iso_range: string;
  }
  
  /**
   * Specifications regarding speed, autofocus, and video capabilities.
   */
  export interface PerformanceSpecs {
    autofocus_system: string;
    max_burst_shooting: string; // e.g., "40 fps"
    shutter_speed_max: string;
    video_resolution_max: string;
    storage_media: string;      // e.g., "Dual CFexpress"
  }
  
  /**
   * Physical attributes and hardware components.
   */
  export interface HardwareFeatures {
    viewfinder: string;
    lcd_screen: string;
    connectivity: string;       // e.g., "Wi-Fi 6E, Bluetooth"
    battery_model: string;
    dimensions: string;
    weight: string;
  }