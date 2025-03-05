// types.ts
export interface SalesData {
  id: string;
  date: string;
  lastEditedOn: string;
  lunch_bento: number;
  lunch_fatture: number;
  lunch_letturaCassa: number;
  lunch_persone: number;
  lunch_yami: number;
  lunch_yamiPulito: number;
  dinner_cocai: number;
  dinner_fatture: number;
  dinner_letturaCassa: number;
  dinner_yami: number;
  dinner_yamiPulito: number;
}

export interface FirestoreData {
  dateString: string;
  lastEditedOn?: string | number;
  lunch?: {
    bento?: number;
    fatture?: number;
    letturaCassa?: number;
    persone?: number;
    yami?: number;
    yamiPulito?: number;
  };
  dinner?: {
    cocai?: number;
    fatture?: number;
    letturaCassa?: number;
    yami?: number;
    yamiPulito?: number;
  };
}