//=============================================================================================
// Mintaprogram: Zöld háromszög. Ervenyes 2018. osztol.
//
// A beadott program csak ebben a fajlban lehet, a fajl 1 byte-os ASCII karaktereket tartalmazhat, BOM kihuzando.
// Tilos:
// - mast "beincludolni", illetve mas konyvtarat hasznalni
// - faljmuveleteket vegezni a printf-et kiveve
// - Mashonnan atvett programresszleteket forrasmegjeloles nelkul felhasznalni es
// - felesleges programsorokat a beadott programban hagyni!!!!!!! 
// - felesleges kommenteket a beadott programba irni a forrasmegjelolest kommentjeit kiveve
// ---------------------------------------------------------------------------------------------
// A feladatot ANSI C++ nyelvu forditoprogrammal ellenorizzuk, a Visual Studio-hoz kepesti elteresekrol
// es a leggyakoribb hibakrol (pl. ideiglenes objektumot nem lehet referencia tipusnak ertekul adni)
// a hazibeado portal ad egy osszefoglalot.
// ---------------------------------------------------------------------------------------------
// A feladatmegoldasokban csak olyan OpenGL fuggvenyek hasznalhatok, amelyek az oran a feladatkiadasig elhangzottak 
// A keretben nem szereplo GLUT fuggvenyek tiltottak.
//
// NYILATKOZAT
// ---------------------------------------------------------------------------------------------
// Nev    : Kovacs Botond Janos
// Neptun : SSEGZO
// ---------------------------------------------------------------------------------------------
// ezennel kijelentem, hogy a feladatot magam keszitettem, es ha barmilyen segitseget igenybe vettem vagy
// mas szellemi termeket felhasznaltam, akkor a forrast es az atvett reszt kommentekben egyertelmuen jeloltem.
// A forrasmegjeloles kotelme vonatkozik az eloadas foliakat es a targy oktatoi, illetve a
// grafhazi doktor tanacsait kiveve barmilyen csatornan (szoban, irasban, Interneten, stb.) erkezo minden egyeb
// informaciora (keplet, program, algoritmus, stb.). Kijelentem, hogy a forrasmegjelolessel atvett reszeket is ertem,
// azok helyessegere matematikai bizonyitast tudok adni. Tisztaban vagyok azzal, hogy az atvett reszek nem szamitanak
// a sajat kontribucioba, igy a feladat elfogadasarol a tobbi resz mennyisege es minosege alapjan szuletik dontes.
// Tudomasul veszem, hogy a forrasmegjeloles kotelmenek megsertese eseten a hazifeladatra adhato pontokat
// negativ elojellel szamoljak el es ezzel parhuzamosan eljaras is indul velem szemben.
//=============================================================================================
#include "framework.h"

const char * const vertexSource = R"(
	#version 330
	precision highp float;

	layout(location = 0) in vec2 in_vertexPosition;
	layout(location = 1) in vec2 in_vertexTexCoord;

	out vec2 v_texCoord;

	void main() {
		v_texCoord = in_vertexTexCoord;
		gl_Position = vec4 (in_vertexPosition, 0.0, 1.0);
	}
)";

const char * const fragmentSource = R"(
#version 330
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;

in vec2 v_texCoord;

struct Ray {
	vec3 origin;
	vec3 direction;
};
	
struct Hit {
	bool didHit;
	vec3 rayOrigin;
	vec3 rayDirection;
	float hitDistance;
	vec3 hitPoint;
	vec3 hitNormal;
	int hitMaterialId;
};
	
struct Sphere {
	vec3 center;
	float radius;
	int materialId;
};

struct Ellipsoid {
	vec3 center;
	vec3 radius;
	int materialId;
};

struct Plane {
	vec3 point;
	vec3 normal;
	int materialId;
};

struct Material {
	bool isReflective;
	bool isRough;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
	float shininess;
	vec3 n;
	vec3 k;
};

uniform struct {
	vec3 direction;
	vec3 energy;
	vec3 ambient;
} light;

const int maxNumMaterials = 10;
const int maxNumSpheres = 10;
const int maxNumEllipsoids = 10;
const int maxBounces = 64;
const float epsilon = 0.001;

uniform Material materials [maxNumMaterials];
uniform Sphere spheres [maxNumSpheres];
uniform Ellipsoid ellipsoids [maxNumEllipsoids];
uniform int numSpheres;
uniform int numEllipsoids;
uniform int numMirrorSides = 3;

uniform int mirrorMaterialId = 0;
	
void hitSphere ( in Ray ray, in Sphere sphere, out Hit hit ) {
	
	hit.rayOrigin = ray.origin;
	hit.rayDirection = ray.direction;
	
	vec3 rayToSphere = ray.origin - sphere.center;
	
	float a = dot (ray.direction, ray.direction);
	float b = dot (rayToSphere, ray.direction) * 2.0;
	float c = dot (rayToSphere, rayToSphere) - sphere.radius * sphere.radius;
	float discriminant = b * b - 4.0 * a * c;
	
	if (discriminant < 0.0) {
		hit.didHit = false;
		return;
	}
	
	float sqrtDiscriminant = sqrt (discriminant);
	float t1 = (-b + sqrtDiscriminant) / 2.0 / a;
	float t2 = (-b - sqrtDiscriminant) / 2.0 / a;
	
	if (t1 <= 0.0) {
		hit.didHit = false;
		return;
	}
	
	float hitT = (t2 > 0.0) ? t2 : t1;
	
	hit.didHit = true;
	hit.hitPoint = ray.origin + ray.direction * hitT;
	hit.hitNormal = normalize (hit.hitPoint - sphere.center);
	hit.hitMaterialId = sphere.materialId;
	hit.hitDistance = hitT;
	
}

// Source: https://stackoverflow.com/questions/52130939/ray-vs-ellipsoid-intersection
void hitEllipsoid (in Ray ray, in Ellipsoid ellipsoid, out Hit hit) {

	hit.didHit = false;
	hit.rayOrigin = ray.origin;
	hit.rayDirection = ray.direction;

	mat3 q;
	q [0][0] = ellipsoid.radius.x;
	q [1][1] = ellipsoid.radius.y;
	q [2][2] = ellipsoid.radius.z;
	mat3 qInv = inverse(q);

	Ray newRay;
	newRay.origin = qInv * (ray.origin - ellipsoid.center);
	newRay.direction = normalize (qInv * ray.direction);

	Hit sphereHit;
	hitSphere (newRay, Sphere (vec3 (0.), 1., ellipsoid.materialId), sphereHit);

	hit.didHit = sphereHit.didHit;
	hit.hitPoint = q * sphereHit.hitPoint + ellipsoid.center;
	hit.hitNormal = sphereHit.hitNormal;
	hit.hitNormal.x /= pow (ellipsoid.radius.x, 2.0);
	hit.hitNormal.y /= pow (ellipsoid.radius.y, 2.0);
	hit.hitNormal.z /= pow (ellipsoid.radius.z, 2.0);
	hit.hitNormal = normalize (hit.hitNormal);
	hit.hitMaterialId = sphereHit.hitMaterialId;
	hit.hitDistance = length (ray.origin - hit.hitPoint);

}

// Source: https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection
void hitPlane ( in Ray ray, in Plane plane, out Hit hit ) {

	hit.didHit = false;

    hit.rayOrigin = ray.origin;
    hit.rayDirection = ray.direction;
    
    float denom = dot(plane.normal, ray.direction);
    if (abs (denom) > 0.001) {
        vec3 diff = plane.point - ray.origin;
        float t = dot (diff, plane.normal) / denom;
        
        if (t > 0.0) {
            
            hit.didHit = true;
            hit.hitPoint = ray.origin + ray.direction * t;
            hit.hitDistance = t;
            hit.hitMaterialId = plane.materialId;
            hit.hitNormal = normalize (plane.normal);
            
        } else {
            hit.didHit = false;
        }
    }

}

void hitCaleidoscopeWalls ( in Ray ray, out Hit hit ) {

	hit.didHit = false;
	hit.rayOrigin = ray.origin;
	hit.rayDirection = ray.direction;

	float alpha = 2.0 * 3.141592653 / float (numMirrorSides);

	for (int i = 0; i < numMirrorSides; i++) {

		vec3 p1 = vec3 (cos (float (i) * alpha), sin (float (i) * alpha), 0.0);
		vec3 p2 = vec3 (cos (float (i + 1) * alpha), sin (float (i + 1) * alpha), 0.0);
	
		vec3 p1p2 = p2 - p1;
		vec3 v = vec3 (0.0, 0.0, 1.0);
		
		vec3 planeNormal = normalize (cross (normalize (p1p2), v));
		planeNormal = normalize (planeNormal);
	
		vec3 pointOnPlane = p1;
	
		Hit planeHit;
		hitPlane (ray, Plane (pointOnPlane, planeNormal, mirrorMaterialId), planeHit);
	
		if (planeHit.didHit) {
			if (!hit.didHit || hit.hitDistance > planeHit.hitDistance) {
				hit = planeHit;
			}
		}

	}

	Hit farPlaneHit;
	hitPlane (ray, Plane (vec3 (0.0, 0.0, 30.0), vec3 (0.0, 0.0, 1.0), 2), farPlaneHit);

	if (farPlaneHit.didHit) {
		if (!hit.didHit || hit.hitDistance > farPlaneHit.hitDistance) {
			hit = farPlaneHit;
		}
	}

}

void trace ( in Ray ray, out Hit hit ) {

	hit.didHit = false;

	for (int i = 0; i < numSpheres; i++) {
		Hit sphereHit;
		hitSphere (ray, spheres [i], sphereHit);

		if (sphereHit.didHit) {
			if (!hit.didHit || hit.hitDistance > sphereHit.hitDistance) {
				hit = sphereHit;
			}
		}
	}

	for (int i = 0; i < numEllipsoids; i++) {
		Hit ellipsoidHit;
		hitEllipsoid (ray, ellipsoids [i], ellipsoidHit);

		if (ellipsoidHit.didHit) {
			if (!hit.didHit || hit.hitDistance > ellipsoidHit.hitDistance) {
				hit = ellipsoidHit;
			}
		}

	}
	
	Hit caleidoscopeWallHit;
	hitCaleidoscopeWalls (ray, caleidoscopeWallHit);
	if (caleidoscopeWallHit.didHit) {
		if (!hit.didHit || hit.hitDistance > caleidoscopeWallHit.hitDistance) {
			hit = caleidoscopeWallHit;
		}
	}

    if ( dot (ray.direction, hit.hitNormal) > 0.0 ) {
        hit.hitNormal = -1.0 * hit.hitNormal;
    }
	
}

Ray getRay ( in vec2 ndc, in float aspect, in vec3 eye ) {
	
	return Ray (
		eye,
		normalize ( vec3 ( ndc.x * aspect, ndc.y, 0.0 ) - eye )
	);
	
}

vec3 getMaterialF0 (in Material mat) {
    return vec3 (
        (pow (mat.n.x - 1.0, 2.0) + pow (mat.k.x, 2.0)) / (pow (mat.n.x + 1.0, 2.0) + pow (mat.k.x, 2.0)),
        (pow (mat.n.y - 1.0, 2.0) + pow (mat.k.y, 2.0)) / (pow (mat.n.y + 1.0, 2.0) + pow (mat.k.y, 2.0)),
        (pow (mat.n.z - 1.0, 2.0) + pow (mat.k.z, 2.0)) / (pow (mat.n.z + 1.0, 2.0) + pow (mat.k.z, 2.0))
    );
}

vec3 fresnel ( in vec3 F0, float cosTheta ) {
	return F0 + (vec3(1.0, 1.0, 1.0) - F0) * pow(cosTheta, 5.0);
}

vec4 calculate ( in vec2 ndc, in float aspect, in vec3 eye ) {
	
	Ray primaryRay = getRay ( ndc, aspect, eye );
	Hit primaryHit;
	trace (primaryRay, primaryHit);

	vec3 radiance = vec3 (0.0);
	vec3 reflectionWeight = vec3 (1.0, 1.0, 1.0);

	if (primaryHit.didHit) {

		Ray ray = primaryRay;
		Hit hit = primaryHit;

		for (int i = 0; i < maxBounces; i++) {

			if (!hit.didHit) {
				break;
			}

			Material material = materials [hit.hitMaterialId];

			if (material.isRough) {

				radiance += reflectionWeight * material.ambient * light.ambient;

				Ray shadowRay = Ray ( 
					hit.hitPoint + hit.hitNormal * 0.001,
					light.direction
				);
				Hit shadowHit;
				trace (shadowRay, shadowHit);

				if (!shadowHit.didHit) {

					float cosTheta = dot (hit.hitNormal, light.direction);

					if (cosTheta > 0.0) {

						radiance += reflectionWeight * light.energy * material.diffuse * cosTheta;

						vec3 halfway = normalize (-hit.rayDirection + light.direction);
						float cosDelta = dot (hit.hitNormal, halfway);

						if (cosDelta > 0.0) {
							radiance += reflectionWeight * light.energy * material.specular * pow (cosDelta, material.shininess);
						}

					}

				}

			}

			if (material.isReflective) {

				reflectionWeight *= fresnel ( getMaterialF0 (material), dot (-hit.rayDirection, hit.hitNormal) );
				ray = Ray (
					hit.hitPoint + hit.hitNormal * 0.001,
					reflect (hit.rayDirection, hit.hitNormal)
				);
				trace (ray, hit);
				
			} else break;

		}

	}

	return vec4 (pow (radiance, vec3 (1. / 2.2)), 1.0);
	
}

vec4 out_finalColor;

void main() {

	vec2 ndc = v_texCoord * 2.0 - 1.0;
	float aspect = u_resolution.x / u_resolution.y;
	
	gl_FragColor = calculate ( ndc, aspect, vec3 (0.0, 0.0, -2.0) );
	
}
)";

GPUProgram gpuProgram;
const float boundarySphereRadius = 1.0;

struct Light {

	vec3 direction;
	vec3 energy;
	vec3 ambient;

	void SetUniforms (
		unsigned int programId,
		char* directionUniformName,
		char* energyUniformName,
		char* ambientUniformName
	) {

		direction.SetUniform (programId, directionUniformName);
		energy.SetUniform (programId, energyUniformName);
		ambient.SetUniform (programId, ambientUniformName);

	}

};

struct Sphere {

	vec3 center;
	vec3 velocity;
	float radius;
	int materialId;

	void SetUniforms (
		unsigned int programId,
		char* nameTemplate,
		int sphereId
	) {

		char uniformName [256];

		sprintf (uniformName, nameTemplate, sphereId, "center");
		center.SetUniform (programId, uniformName);

		sprintf (uniformName, nameTemplate, sphereId, "radius");
		int location = glGetUniformLocation (programId, uniformName);
		if (location >= 0) {
			glUniform1f (location, radius);
		}

		sprintf (uniformName, nameTemplate, sphereId, "materialId");
		location = glGetUniformLocation (programId, uniformName);
		if (location >= 0) {
			glUniform1i (location, materialId);
		}

	}

};

struct Ellipsoid {

	vec3 center;
	vec3 velocity;
	vec3 radius;
	int materialId;

	void SetUniforms (
		unsigned int programId,
		char* nameTemplate,
		int sphereId
	) {

		char uniformName [256];

		sprintf (uniformName, nameTemplate, sphereId, "center");
		center.SetUniform (programId, uniformName);

		sprintf (uniformName, nameTemplate, sphereId, "radius");
		radius.SetUniform (programId, uniformName);
		
		sprintf (uniformName, nameTemplate, sphereId, "materialId");
		int location = glGetUniformLocation (programId, uniformName);
		if (location >= 0) {
			glUniform1i (location, materialId);
		}

	}

};

struct Material {

	bool isReflective;
	bool isRough;
	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
	float shininess;
	vec3 n;
	vec3 k;

	void SetUniforms (
		unsigned int programId,
		char* nameTemplate,
		int materialId
	) {

		char uniformName [256];

		sprintf (uniformName, nameTemplate, materialId, "isReflective");
		int location = glGetUniformLocation (programId, uniformName);
		if (location >= 0) {
			glUniform1i (location, isReflective ? 1 : 0);
		}

		sprintf (uniformName, nameTemplate, materialId, "isRough");
		location = glGetUniformLocation (programId, uniformName);
		if (location >= 0) {
			glUniform1i (location, isRough ? 1 : 0);
		}

		sprintf (uniformName, nameTemplate, materialId, "ambient");
		ambient.SetUniform (programId, uniformName);

		sprintf (uniformName, nameTemplate, materialId, "diffuse");
		diffuse.SetUniform (programId, uniformName);

		sprintf (uniformName, nameTemplate, materialId, "specular");
		specular.SetUniform (programId, uniformName);

		sprintf (uniformName, nameTemplate, materialId, "shininess");
		location = glGetUniformLocation (programId, uniformName);
		if (location >= 0) {
			glUniform1f (location, shininess);
		}

		sprintf (uniformName, nameTemplate, materialId, "n");
		n.SetUniform (programId, uniformName);

		sprintf (uniformName, nameTemplate, materialId, "k");
		k.SetUniform (programId, uniformName);

	}

};

inline float frand () {
	return (float) rand () / (float) RAND_MAX;
}

struct RayTracingGame {

	unsigned int fullScreenQuadVao;
	unsigned int fullScreenQuadVbo;

	vec2 resolution;
	float gameTime = 0.0;

	int numSpheres = 7;

	std::vector <Material> materials;
	std::vector <Sphere> spheres;
	std::vector <Ellipsoid> ellipsoids;
	Light light;

	int mirrorMaterialId = 0;
	int numMirrorSides = 3;

	void CreateMaterials () {

		Material goldMaterial;
		goldMaterial.isReflective = true;
		goldMaterial.isRough = false;
		goldMaterial.n = vec3 (0.17, 0.35, 1.5);
		goldMaterial.k = vec3 (3.1, 2.7, 1.9);

		materials.push_back (goldMaterial);

		Material silverMaterial;
		silverMaterial.isReflective = true;
		silverMaterial.isRough = false;
		silverMaterial.n = vec3 (0.14, 0.16, 0.13);
		silverMaterial.k = vec3 (4.1, 2.3, 3.1);

		materials.push_back (silverMaterial);

		Material whiteMaterial;
		whiteMaterial.isReflective = false;
		whiteMaterial.isRough = true;
		whiteMaterial.ambient = vec3 (1.0, 1.0, 1.0);
		whiteMaterial.diffuse = vec3 (1.0, 1.0, 1.0);
		whiteMaterial.specular = vec3 (0.0, 0.0, 0.0);
		whiteMaterial.shininess = 0.0;
		materials.push_back (whiteMaterial);

		for (int i = 0; i < numSpheres; i++) {

			Material randomDiffuseMaterial;
			randomDiffuseMaterial.isReflective = false;
			randomDiffuseMaterial.isRough = true;
			randomDiffuseMaterial.ambient = vec3 (0.5 * frand (), 0.5 * frand (), 0.5 * frand ());
			randomDiffuseMaterial.diffuse = vec3 (frand () * 0.8 + 0.2, frand () * 0.8 + 0.2, frand () * 0.8 + 0.2);
			randomDiffuseMaterial.specular = vec3 (frand () * 0.8 + 0.2, frand () * 0.8 + 0.2, frand () * 0.8 + 0.2);
			randomDiffuseMaterial.shininess = 250.0 * frand () + 20.0;

			materials.push_back (randomDiffuseMaterial);

		}

	}

	void CreateSpheres () {

		for (int i = 0; i < numSpheres; i++) {

			Ellipsoid e;
			e.center = vec3 ( frand () * 0.5 - 0.25, frand () * 0.5 - 0.25, 12.0 + 3.0 * frand () );
			e.radius = vec3 ( 0.12 + frand () * 0.12, 0.12 + frand () * 0.12, 0.12 + frand () * 0.12 );
			e.materialId = 3 + i;

			ellipsoids.push_back (e);

		}

	}

	void CreateLight () {

		light.direction = vec3 (0.0, 0.0, -1.0);
		light.ambient = vec3 (0.5, 0.5, 0.5);
		light.energy = vec3 (2.0, 2.0, 2.0);

	}

	void SetMaterialsInShader () {

		for (int i = 0; i < materials.size (); i++) {

			auto &mat = materials [i];
			mat.SetUniforms (
				gpuProgram.getId (),
				"materials[%d].%s",
				i
			);

		}

	}

	void SetSpheresInShader () {

		for (int i = 0; i < spheres.size (); i++) {

			auto &sp = spheres [i];
			sp.SetUniforms (
				gpuProgram.getId (),
				"spheres[%d].%s",
				i
			);

		}

		int location = glGetUniformLocation (gpuProgram.getId (), "numSpheres");
		if (location >= 0) {
			glUniform1i (location, spheres.size ());
		}

		for (int i = 0; i < ellipsoids.size (); i++) {

			auto &e = ellipsoids [i];
			e.SetUniforms (
				gpuProgram.getId (),
				"ellipsoids[%d].%s",
				i
			);

		}

		location = glGetUniformLocation (gpuProgram.getId (), "numEllipsoids");
		if (location >= 0) {
			glUniform1i (location, ellipsoids.size ());
		}

	}

	void SetLightInShader () {

		light.SetUniforms (
			gpuProgram.getId (),
			"light.direction",
			"light.energy",
			"light.ambient"
		);

	}

	void SetMirrorDataInShader () {

		int location = glGetUniformLocation (gpuProgram.getId (), "numMirrorSides");
		if (location >= 0) {
			glUniform1i (location, numMirrorSides);
		}

		location = glGetUniformLocation (gpuProgram.getId (), "mirrorMaterialId");
		if (location >= 0) {
			glUniform1i (location, mirrorMaterialId);
		}

	}

	void Setup () {

		srand (13567812);

		CreateLight ();
		CreateMaterials ();
		CreateSpheres ();

		glGenVertexArrays (1, &fullScreenQuadVao);
		glBindVertexArray (fullScreenQuadVao);

		glGenBuffers (1, &fullScreenQuadVbo);
		glBindBuffer (GL_ARRAY_BUFFER, fullScreenQuadVbo);

		float vertexData [] = {

			-1.0, 1.0, 0.0, 0.0,
			1.0, 1.0, 1.0, 0.0,
			-1.0, -1.0, 0.0, 1.0,

			1.0, 1.0, 1.0, 0.0,
			1.0, -1.0, 1.0, 1.0,
			-1.0, -1.0, 0.0, 1.0

		};

		glBufferData (
			GL_ARRAY_BUFFER,
			sizeof (vertexData),
			vertexData,
			GL_STATIC_DRAW
		);

		glEnableVertexAttribArray (0);
		glEnableVertexAttribArray (1);

		glVertexAttribPointer (
			0,
			2,
			GL_FLOAT,
			GL_FALSE,
			4 * sizeof (float),
			(void*) 0
		);
		glVertexAttribPointer (
			1,
			2,
			GL_FLOAT,
			GL_FALSE,
			4 * sizeof (float),
			(void*) (2 * sizeof (float))
		);

		glBindVertexArray (0);
		glBindBuffer (GL_ARRAY_BUFFER, 0);

	}

	void Draw () {

		resolution.x = (float) windowWidth;
		resolution.y = (float) windowHeight;

		gpuProgram.Use ();
		SetSpheresInShader ();
		SetMaterialsInShader ();
		SetLightInShader ();
		SetMirrorDataInShader ();

		resolution.SetUniform (gpuProgram.getId (), "u_resolution");
		int u_timeLocation = glGetUniformLocation (gpuProgram.getId(), "u_time");
		if (u_timeLocation >= 0) {
			glUniform1f (u_timeLocation, gameTime);
		}

		glBindVertexArray (fullScreenQuadVao);
		glDrawArrays (GL_TRIANGLES, 0, 6);
		glBindVertexArray (0);

	}

	void Update (float delta) {

		gameTime += delta;

		for (auto &e : ellipsoids) {

			e.velocity = e.velocity + vec3 (frand (), frand (), 0.0) * delta;
			
			if (abs (e.center.x + e.velocity.x * delta) >= 1.0 - e.radius.x) {
				e.velocity.x *= -1.0;
			}

			if (abs (e.center.y + e.velocity.y * delta) >= 1.0 - e.radius.y) {
				e.velocity.y *= -1.0;
			}
			
			e.center = e.center + e.velocity * delta;

		}

	}

};

RayTracingGame game;

long lastFrameTimestamp;

void onInitialization() {
	
	game.Setup ();

	glViewport(0, 0, windowWidth, windowHeight);

	gpuProgram.Create(vertexSource, fragmentSource, "out_finalColor");
	
}

void onDisplay() {
	
	glClearColor(0, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT);

	game.Draw ();

	glutSwapBuffers();
	
}

void onKeyboard(unsigned char key, int pX, int pY) {
	if (key == 'd') glutPostRedisplay();

	if (key == 's') {
		game.mirrorMaterialId = 1;
	}

	if (key == 'g') {
		game.mirrorMaterialId = 0;
	}

	if (key == 'a') {
		game.numMirrorSides += 1;
	}

	glutPostRedisplay();
	
}

void onKeyboardUp(unsigned char key, int pX, int pY) {
}

void onMouseMotion(int pX, int pY) {
	
	float cX = 2.0f * pX / windowWidth - 1;
	float cY = 1.0f - 2.0f * pY / windowHeight;
	
}

void onMouse(int button, int state, int pX, int pY) {

}

void onIdle() {
	
	long time = glutGet(GLUT_ELAPSED_TIME);
	long deltaMs = time - lastFrameTimestamp;
	lastFrameTimestamp = time;
	
	float delta = (float) deltaMs / 1000.0f;
	if (delta > 1.0f) delta = 0.0f;

	game.Update (delta);
	
	glutPostRedisplay();
	
}
