package com.google.olc;

public class Point {
	double x = Double.POSITIVE_INFINITY;
	double y = Double.POSITIVE_INFINITY;
	public Point(double lat, double lon) {
		setLatitude(lat);
		setLongitude(lon);
	}
	public double getX() {
		return x;
	}
	public void setX(double x) {
		this.x = x;
	}
	public double getY() {
		return y;
	}
	public void setY(double y) {
		this.y = y;
	}
	
	public void setLatitude(double latitude) {
		 x=latitude;
	}
	
	public double getLatitude() {
		return x;
	}
	
	public void setLongitude(double longitude) {
		y = longitude;
	}
	public double getLongitude() {
		return y;
	}
}
