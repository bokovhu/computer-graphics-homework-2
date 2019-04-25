import math

class Vec3:
	def __init__(self, x, y, z):
		self.x = x
		self.y = y
		self.z = z

class Material:
	def __init__(self, n, k):
		self.n = n
		self.k = k
		
def f0(material):
	res = Vec3(0.0, 0.0, 0.0)
	res.x = ( math.pow(material.n.x - 1.0, 2.0) + math.pow(material.k.x, 2.0) ) / ( math.pow (material.n.x + 1.0, 2.0) + math.pow (material.k.x, 2.0) )
	res.y = ( math.pow(material.n.y - 1.0, 2.0) + math.pow(material.k.y, 2.0) ) / ( math.pow (material.n.y + 1.0, 2.0) + math.pow (material.k.y, 2.0) )
	res.z = ( math.pow(material.n.z - 1.0, 2.0) + math.pow(material.k.z, 2.0) ) / ( math.pow (material.n.z + 1.0, 2.0) + math.pow (material.k.z, 2.0) )
		
	return res
	
def printvec(vec):
	print (f'vec3 ({vec.x}, {vec.y}, {vec.z})')
	
matN = Vec3 (0.0, 0.0, 0.0)
matN.x = float (input ('n.x = '))
matN.y = float (input ('n.y = '))
matN.z = float (input ('n.z = '))

matK = Vec3 (0.0, 0.0, 0.0)
matK.x = float (input ('k.x = '))
matK.y = float (input ('k.y = '))
matK.z = float (input ('k.z = '))

printvec (f0 (Material (matN, matK)))