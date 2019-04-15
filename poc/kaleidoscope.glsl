
#define PI 3.141592653

// If it doesn't work, here's the checklist:

// 1. getRay function, check vector subtractions
// 2. intersectEllipsoid function, check matrix mult order
// 3. intersectEllipsoid function, check matrices

precision highp float;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

struct Material {
	bool reflective;
	vec3 diffuse;
	vec3 n;
	vec3 k;
};
	
struct Ellipsoid {
	vec3 center;
	vec3 radius;
	int materialId;
};
    
struct Sphere {
    vec3 center;
    float radius;
    int materialId;
};
	
struct Ray {
	vec3 origin;
	vec3 direction;
};

struct Hit {
	bool didHit;
	vec3 rayOrigin;
	vec3 rayDirection;
	vec3 hitPoint;
	vec3 hitNormal;
	int hitMaterialId;
    float hitDistance;
};
    
struct Plane {
    vec3 point;
    vec3 normal;
    int materialId;
};
	
const int numMirrorSides = 6;
const vec3 lightDir = normalize (vec3 (0.0, -0.0, -1.0));
const vec3 lightAmbient = vec3 (1.0, 1.0, 1.0);
const vec3 lightEnergy = vec3 (20.0, 20.0, 20.0);
const vec3 cameraDir = normalize (vec3 (0.0, 0.0, 1.0));
const vec3 cameraEyePoint = vec3 (0.0, 0.0, -6.0);

// TODO: Implement proper camera

const Material diffuseMaterial1 = Material (false, vec3(0.2, 0.0, 0.0), vec3(0.0), vec3(0.0));
const Material diffuseMaterial2 = Material (false, vec3(0.0, 0.2, 0.0), vec3(0.0), vec3(0.0));
const Material diffuseMaterial3 = Material (false, vec3(0.0, 0.0, 0.2), vec3(0.0), vec3(0.0));
const Material diffuseMaterial4 = Material (false, vec3(1.0, 1.0, 1.0), vec3(0.0), vec3(0.0));
const Material goldMaterial = Material(true, vec3(0.0), vec3 (0.17, 0.35, 1.5), vec3 (3.1, 2.7, 1.9));
const Material silverMaterial = Material(true, vec3(0.0), vec3 (0.14, 0.16, 0.13), vec3 (4.1, 2.3, 3.1));

const Ellipsoid [] ELLIPSOIDS = Ellipsoid [] (
    Ellipsoid (vec3 (-1.5, 0.6, 5.2), vec3 (0.3, 0.35, 0.1), 1),
    Ellipsoid (vec3 (1.2, -0.9, 5.0), vec3 (0.18, 0.2, 0.3), 1)
);

const Plane farPlane = Plane (
    vec3 (0.0, 0.0, 20.0),
    vec3 (0.0, 0.0, 1.0),
    4
);

const int numSpheres = 3;

const int maxBounces = 64;

Material getMaterialById (int id) {
	if (id == 0) return diffuseMaterial1;
    if (id == 1) return diffuseMaterial2;
    if (id == 2) return diffuseMaterial3;
	if (id == 3) return goldMaterial;
    if (id == 4) return diffuseMaterial4;
	return silverMaterial;
}

void intersectSphere (in Ray ray, in Sphere sphere, out Hit hit) {
    
    hit.rayOrigin = ray.origin;
    hit.rayDirection = ray.direction;
    
    vec3 dist = ray.origin - sphere.center;
    
    float a = dot (ray.direction, ray.direction);
    float b = dot (dist, ray.direction) * 2.0;
    float c = dot (dist, dist) - sphere.radius * sphere.radius;
    float discr = b * b - 4.0 * a * c;
    
    if (discr < 0.0) {
        hit.didHit = false;
        return;
    }
    
    float sqrt_discr = sqrt (discr);
    float t1 = (-b + sqrt_discr) / 2.0 / a;
    float t2 = (-b - sqrt_discr) / 2.0 / a;
    
    if (t1 <= 0.0) {
        hit.didHit = false;
        return;
    }
    
    float hitT = (t2 > 0.0) ? t2 : t1;
    
    hit.didHit = true;
    hit.hitPoint = ray.origin + ray.direction * hitT;
    hit.hitNormal = normalize ((hit.hitPoint - sphere.center));
    hit.hitMaterialId = sphere.materialId;
    hit.hitDistance = hitT;
    
}

void intersectEllipsoid (in Ray ray, in Ellipsoid ellipsoid, out Hit hit) {
    
    
    
}

void intersectPlane (in Ray ray, in Plane plane, out Hit hit) {
    
    hit.rayOrigin = ray.origin;
    hit.rayDirection = ray.direction;
    
    float denom = dot(plane.normal, ray.direction);
    if (denom > 0.001) {
        vec3 p010 = plane.point - ray.origin;
        float t = dot (p010, plane.normal) / denom;
        
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

void intersectMirrors (in Ray ray, out Hit hit) {
    
    Hit bestHit;
    float angle = 2.0 * PI / float (numMirrorSides);
    for (int i = 0; i < numMirrorSides; i++) {
        
        vec3 p1 = vec3 (cos (float (i) * angle), sin (float (i) * angle), 0.0) * 0.5;
        vec3 p2 = vec3 (cos (float (i + 1) * angle), sin (float (i + 1) * angle), 0.0) * 0.5;
        vec3 p1p2 = p2 - p1;
        vec3 v = vec3 (0.0, 0.0, 1.0);
        
        vec3 planeNormal = normalize (cross (normalize (p1p2), v));
        planeNormal = normalize (planeNormal);
        
        vec3 planePoint = p1;
        Plane plane = Plane (planePoint, planeNormal, 3);
        
        Hit planeHit;
        intersectPlane (ray, plane, planeHit);
        
        if (planeHit.didHit) {
            if (!bestHit.didHit || bestHit.hitDistance >= planeHit.hitDistance) {
                bestHit = planeHit;
            }
        }
        
    }
    
    hit = bestHit;
    
}

void getRay (in vec2 pixelNdc, in float aspect, out Ray ray) {
	
	ray.origin = cameraEyePoint;
    ray.direction = normalize ( vec3 (pixelNdc.x * aspect, pixelNdc.y, 0.0) - cameraEyePoint );
    
}

void rayTrace (in Ray ray, out Hit hit, in Sphere [numSpheres] spheres) {
	
	hit.didHit = false;
	
    Hit innerHit;
    for (int i = 0; i < numSpheres; i++) {
        
        Hit currentHit;
        Sphere currentSphere = spheres [i];
        intersectSphere (ray, currentSphere, currentHit);
        
        if (currentHit.didHit) {
            if (!innerHit.didHit || innerHit.hitDistance > currentHit.hitDistance) {
                innerHit = currentHit;
            }
        }
        
    }
    
    Hit mirrorsHit;
    intersectMirrors (ray, mirrorsHit);
    
    if (mirrorsHit.didHit && (mirrorsHit.hitDistance < innerHit.hitDistance || !innerHit.didHit)) {
        innerHit = mirrorsHit;
    }
    
    Hit farPlaneHit;
    intersectPlane (ray, farPlane, farPlaneHit);
    
    if (farPlaneHit.didHit && (farPlaneHit.hitDistance < innerHit.hitDistance || !innerHit.didHit)) {
        innerHit = farPlaneHit;
    }
    
    hit = innerHit;
    
    if ( dot (ray.direction, hit.hitNormal) > 0.0 ) {
        hit.hitNormal = -1.0 * hit.hitNormal;
    }
	
}

vec3 getMaterialF0 (in Material mat) {
    return vec3 (
        (pow (mat.n.x - 1.0, 2.0) + pow (mat.k.x, 2.0)) / (pow (mat.n.x + 1.0, 2.0) + pow (mat.k.x, 2.0)),
        (pow (mat.n.y - 1.0, 2.0) + pow (mat.k.y, 2.0)) / (pow (mat.n.y + 1.0, 2.0) + pow (mat.k.y, 2.0)),
        (pow (mat.n.z - 1.0, 2.0) + pow (mat.k.z, 2.0)) / (pow (mat.n.z + 1.0, 2.0) + pow (mat.k.z, 2.0))
    );
}

vec3 Fresnel(vec3 F0, float cosTheta) { 
    return F0 + (vec3(1.0, 1.0, 1.0) - F0) * pow(cosTheta, 5.0);
}

void calculateColor ( in vec2 pixelNdc, in float aspect, in Sphere [numSpheres] spheres, out vec4 finalColor ) {
    
    Ray primaryRay;
    getRay (pixelNdc, aspect, primaryRay);
    
    Hit primaryHit;
    rayTrace (primaryRay, primaryHit, spheres);
    
    vec3 result = vec3 (0.0, 0.0, 0.0);
    vec3 weight = vec3 (1.0, 1.0, 1.0);
        
    
    if (primaryHit.didHit) {
        
        Ray ray = primaryRay;
        Hit hit = primaryHit;
        
        bool didBreak = false;
        
        for (int i = 0; i < maxBounces; i++) {
            
            if (!hit.didHit) {
                result = weight * lightAmbient;
                break;
            }
            
        	Material mat = getMaterialById (hit.hitMaterialId);
            
            if (mat.reflective) {
                
                weight *= Fresnel ( getMaterialF0 (mat), dot(-hit.rayDirection, hit.hitNormal) );
                ray.origin = hit.hitPoint + hit.hitNormal * 0.001;
                ray.direction = reflect (hit.rayDirection, hit.hitNormal);
                
                rayTrace (ray, hit, spheres);
                
            } else {
            
                result += weight * lightAmbient;

                float cosTheta = dot (hit.hitNormal, lightDir);

                if (cosTheta > 0.0) {

                    result += weight * lightEnergy * mat.diffuse * cosTheta;

                }
                
                didBreak = true;
                break;
                
            }
                
        }
        
        if (!didBreak) {
            result = weight * lightAmbient;
        }
        
    } else {
        result = weight * lightAmbient;
    }
    
    finalColor = vec4 (result / 5.0, 1.0);
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    float aspect = iResolution.x / iResolution.y;
	vec2 pixelNdc = 2.0 * (( fragCoord.xy / iResolution.xy ) - 0.5);

    Sphere [] spheres = Sphere [] (
        Sphere (
            vec3 (
                -0.15 + sin (iTime * 13.6 + 12.4) * 0.1, 
                0.3 + cos (iTime * 18.32 + 8.7) * 0.12, 
                13.0
            ), 
            0.1, 0
        ),
        Sphere (
            vec3 (
                0.1 + sin (iTime * 7.0 + 32.56) * 0.07, 
                -0.18 + cos (iTime * 3.6 + 9.65) * 0.14, 
                14.0
            ), 
            0.15, 
            1
        ),
        Sphere (
            vec3 (
                -0.3 + sin (iTime * 16.72 + 231.07) * 0.094,
                0.02 + cos (iTime * 5.136 + 4.17) * 0.11, 
                15.0
            ), 
            0.2, 
            2
        )
    );
    
	calculateColor (pixelNdc, aspect, spheres, fragColor);

}