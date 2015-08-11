package com.google.olc;

public class CodeArea {
	private double latitudeLo;
	private double longitudeLo;
	private double latitudeHi;
	private double longitudeHi;
	private int codeLength;
	private double latitudeCenter;
	private double longitudeCenter;

	CodeArea(double latitudeLo, double longitudeLo, double latitudeHi, double longitudeHi, int codeLength) {
		this.setLatitudeLo(latitudeLo);
		this.longitudeLo = longitudeLo;
		this.latitudeHi = latitudeHi;
		this.longitudeHi = longitudeHi;
		this.codeLength = codeLength;
		this.latitudeCenter = Math.min(latitudeLo + (latitudeHi - latitudeLo) / 2, OpenLocationCode.LATITUDE_MAX_);
		this.longitudeCenter = Math.min(longitudeLo + (longitudeHi - longitudeLo) / 2, OpenLocationCode.LONGITUDE_MAX_);
	}

	public double getLongitudeLo() {
		return longitudeLo;
	}

	public void setLongitudeLo(double longitudeLo) {
		this.longitudeLo = longitudeLo;
	}

	public double getLatitudeHi() {
		return latitudeHi;
	}

	public void setLatitudeHi(double latitudeHi) {
		this.latitudeHi = latitudeHi;
	}

	public double getLongitudeHi() {
		return longitudeHi;
	}

	public void setLongitudeHi(double longitudeHi) {
		this.longitudeHi = longitudeHi;
	}

	public int getCodeLength() {
		return codeLength;
	}

	public void setCodeLength(int codeLength) {
		this.codeLength = codeLength;
	}

	public double getLatitudeCenter() {
		return latitudeCenter;
	}

	public void setLatitudeCenter(double latitudeCenter) {
		this.latitudeCenter = latitudeCenter;
	}

	public double getLongitudeCenter() {
		return longitudeCenter;
	}

	public void setLongitudeCenter(double longitudeCenter) {
		this.longitudeCenter = longitudeCenter;
	}

	public double getLatitudeLo() {
		return latitudeLo;
	}

	public void setLatitudeLo(double latitudeLo) {
		this.latitudeLo = latitudeLo;
	}

	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		long temp;
		temp = Double.doubleToLongBits(latitudeHi);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(latitudeLo);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(longitudeHi);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		temp = Double.doubleToLongBits(longitudeLo);
		result = prime * result + (int) (temp ^ (temp >>> 32));
		return result;
	}
	static double TOLERANCE = 0.000001;
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		CodeArea other = (CodeArea) obj;
		if (Math.abs(latitudeHi-other.latitudeHi)>TOLERANCE)
			return false;
		if (Math.abs(longitudeHi-other.longitudeHi)>TOLERANCE)
			return false;
		if (Math.abs(latitudeLo-other.latitudeLo)>TOLERANCE)
			return false;
		if (Math.abs(longitudeLo-other.longitudeLo)>TOLERANCE)
			return false;

		return true;
	}

	@Override
	public String toString() {
		return "CodeArea [latitudeLo=" + latitudeLo + ", longitudeLo=" + longitudeLo + ", latitudeHi=" + latitudeHi
		    + ", longitudeHi=" + longitudeHi + ", codeLength=" + codeLength + ", latitudeCenter=" + latitudeCenter
		    + ", longitudeCenter=" + longitudeCenter + "]";
	}
	
	
	
}