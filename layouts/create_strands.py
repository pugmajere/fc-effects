#!/usr/bin/python

points = []

adj = 50 / 2 * 0.01

def f(x):
    return [0.01 * x - adj, 0.2 * x - adj, 0.05 * x - adj]

def g(x):
    return [0.01 * x - adj, 0.25 * x - adj, 0.05 * x - adj]

def h(x):
    return [0.01 * x - adj, 0.175 * x - adj, 0.05 * x - adj]

for i in range(50):
    points.append(f(i))

for i in range(50):
    points.append(g(i))

for i in range(50):
    points.append(h(i))

def PointToString(point):
    return '{"point": [%f, %f, %f]}' % (point[0], point[1], point[2])

def PointsToStrings(points):
    return [PointToString(p) for p in points]


print '[\n  %s\n]' % ',\n  '.join(PointsToStrings(points))
